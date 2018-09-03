# ComputeShaderExamples
Tutorial on some basic compute shaders used for gpu particle sims

Point is that you download the files and edit them and test, and you shall learn.

Simplest one is the "Snow" script and compute shader, so i will be demonstrating on it.

After reading this you should check the other scripts and shaders and see how they work.



![](/Snow.gif)

![](/Fountain.gif)

![](/Attractor2.gif)


## Particle's data

When opening snow.cs first thing you will see is the:

~~~
    private struct Particle
    {
        public Vector3 position;
        public float lifetime;
    }
~~~

So that tells us our particles have a position and a lifetime.

If you check Snow.compute you will see it has a:

~~~
struct Particle
{
	float3 position;
	float lifetime;
};
~~~

Which is basically the same thing. Those two must always be same. (in terms of fields and their names)

You can of course add and remove more fields to suit your needs.

## Creating particles

In Snow.cs's Start method:

~~~
        // Initialize the Particle at the start
        Particle[] particleArray = new Particle[particleCount];
        for (int i = 0; i < particleCount; ++i)
        {
            particleArray[i].position.x = Random.Range(-50f, 50f);
            particleArray[i].position.y = 0;
            particleArray[i].position.z = Random.Range(-50f, 50f);

            particleArray[i].lifetime = Random.Range(0f, 25f);
        }
~~~

A particle array (buffer) is made, and a position and lifetime is randomly assigned to each particle.

That array is then passed to the ComputeBuffer so it knows what data its working on:

~~~
        // Create the ComputeBuffer holding the Particles
        particleBuffer = new ComputeBuffer(particleCount, SIZE_PARTICLE);
        particleBuffer.SetData(particleArray);
        
        .
        .
        .
        
        // Bind the ComputeBuffer to the shader and the compute shader
        computeShader.SetBuffer(mComputeShaderKernelID, "particleBuffer", particleBuffer);
        material.SetBuffer("particleBuffer", particleBuffer);
~~~

The material also needs the particleBuffer because it uses their position to draw them there.
(struct PS_INPUT in material shader needs to have color and position at least)

In TintedDistance shader the position is also used to calc distance from camera to particle and fade it accordingly.

## Updating particles 1

So now we want the compute shader to do something on each particle every frame.
We want the compute shader to do it because they are done on gpu, and gpu allows for great parallelism,
resulting in great performance boost than if you were doing it on the cpu from say C#.

The compute shader needs to know the particle data structure, which is the "struct particle" as described in first step.
It needs to hold the particleBuffer so it knows data of each particle,
and a float deltaTime which is used to determine how much the particles should move.
deltaTime is set in update in Snow.cs:

~~~
computeShader.SetFloat("deltaTime", Time.deltaTime);
~~~

that way the compute shader can know how much time has passed irl between each frame, so it moves the particles the right amount.


And is later rendered (Snow.cs):

~~~
    void OnRenderObject()
    {
        material.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Points, 1, particleCount);
    }
~~~

## Updating particles 2

Snow.cs tells the compute shader when to do its computations:

~~~
        // Find the id of the kernel
        mComputeShaderKernelID = computeShader.FindKernel("CSMain");
        
        .
        .
        .
        
        // Update the Particles
        computeShader.Dispatch(mComputeShaderKernelID, mWarpCount, 1, 1);
~~~

At top of snow.compute you can see:

~~~
#pragma kernel CSMain
~~~

That is used to know which method to execute when the compute shader is told to do its calculations:

~~~
void CSMain(uint3 id : SV_DispatchThreadID)
{
  .
  // id is assigned when snow.cs calls Dispatch
  .
}
~~~

FindKernel, pragma kernel and name of kernel method (in this case void CSMain) all must have same name, in this case "CSMain".

## Updating particles 3

The "kernel" is the method that does all the calculations.

In snow.compute those calculations are just moving each particle down and updating its lifetime:

~~~
	float3 delta = float3(0, -2, 0); //gravity

	particleBuffer[id.x].position += delta * deltaTime;
	particleBuffer[id.x].lifetime += deltaTime;
~~~

and reseting their positions if their lifetime crosses a threshold:

~~~
	if (particleBuffer[id.x].lifetime > 25) {
		particleBuffer[id.x].lifetime = 0;
		particleBuffer[id.x].position.y = 0;
	}
~~~

## Making your own thing

So now lets add something, like each particle having its own speed!

So first you want to include a speed parameter in the particle data (in both .cs and .compute):

~~~
private struct Particle
    {
        public Vector3 position;
        public float lifetime;
        public float speed;
    }
~~~

~~~
struct Particle
{
	float3 position;
	float lifetime;
	float speed;
};
~~~

and change the csmain kernel to actually use the speed when calculating motion:

~~~
particleBuffer[id.x].position += delta * deltaTime * particleBuffer[id.x].speed;
~~~

You also want to make the script assign each particle its own speed on start:

~~~
            particleArray[i].speed = Random.Range(0.5f, 5f);
~~~

So that should be it, right? Well when you compile you get two errors similar to theese:

~~~
ArgumentException: ComputeBuffer.SetData() : C# Data stride (16 bytes) is not integer multiple of Compute Buffer stride (24 bytes)

Compute shader (Snow): Property (particleBuffer) at kernel index (0) is not set
~~~

So it says we are trying to fit 24 bytes of data in a 16 byte wide slot! (kinda)

Solution is to edit this in Snow.cs:

~~~
private const int SIZE_PARTICLE = 16;
~~~

to be what it says it needs to be, in this case 24 bytes:

~~~
private const int SIZE_PARTICLE = 24;
~~~

Now it should compile fine, with each particle moving down at its own speed.
