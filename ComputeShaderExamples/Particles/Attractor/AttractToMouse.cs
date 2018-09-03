using UnityEngine;

public class AttractToMouse : MonoBehaviour
{

	/// Particle data structure used by the shader and the compute shader. Must be same in both.
	private struct Particle
	{
		public Vector3 position;
		public Vector3 velocity;
	}

    /// Number of Particle created in the system.
    public int particleCount = 10000;

    /// Material used to draw the Particle on screen.
    public Material material;

    /// Compute shader used to update the Particles.
    public ComputeShader computeShader;

    /// Size in octet of the Particle struct. To be changed if particle struct changed.
    private const int SIZE_PARTICLE = 24;

	/// Id of the kernel used.
	private int mComputeShaderKernelID;

	/// Buffer holding the Particles.
	ComputeBuffer particleBuffer;

	/// Number of particle per warp.
	private const int WARP_SIZE = 256;

	/// Number of warp needed.
	private int mWarpCount;

	void Start()
	{
		// Calculate the number of warp needed to handle all the particles
		if (particleCount <= 0)
			particleCount = 1;
		mWarpCount = Mathf.CeilToInt((float)particleCount / WARP_SIZE);

		// Initialize the Particle at the start
		Particle[] particleArray = new Particle[particleCount];
		for (int i = 0; i < particleCount; ++i)
		{
            particleArray[i].position.x = Random.Range(-2f, 2f);
			particleArray[i].position.y = Random.Range(-2f, 2f);
            particleArray[i].position.z = Random.Range(-2f, 2f);

            particleArray[i].velocity.x = 0;
			particleArray[i].velocity.y = 0;
			particleArray[i].velocity.z = 0;
		}

		// Create the ComputeBuffer holding the Particles
		particleBuffer = new ComputeBuffer(particleCount, SIZE_PARTICLE);
		particleBuffer.SetData(particleArray);

		// Find the id of the kernel
		mComputeShaderKernelID = computeShader.FindKernel("CSMain");

		// Bind the ComputeBuffer to the shader and the compute shader
		computeShader.SetBuffer(mComputeShaderKernelID, "particleBuffer", particleBuffer);
		material.SetBuffer("particleBuffer", particleBuffer);
	}

	void OnDestroy()
	{
		if (particleBuffer != null)
			particleBuffer.Release();
	}
	
	// Update is called once per frame
	void Update()
	{
        Vector3 m = Input.mousePosition;
        m.z = -transform.position.z;

        Vector3 mousePosition = Camera.main.ScreenToWorldPoint(m);
        float[] mousePosition2D = {mousePosition.x, mousePosition.y};

		// Send datas to the compute shader
		computeShader.SetFloat("deltaTime", Time.deltaTime);
		computeShader.SetFloats("mousePosition", mousePosition2D);

		// Update the Particles
		computeShader.Dispatch(mComputeShaderKernelID, mWarpCount, 1, 1);
	}

	void OnRenderObject()
	{
		material.SetPass(0);
		Graphics.DrawProcedural(MeshTopology.Points, 1, particleCount);
	}
	
}
