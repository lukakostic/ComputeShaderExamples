// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TintedAndRandom"
{
	Properties
	{
		_Tint ("Tint", Color) = (0, 0, 0.5, 0.3)
		_Randomness ("Random", Range(0.0, 1.0)) = 0.5
	}

	SubShader 
	{
		Pass 
		{
			Blend SrcAlpha one

			CGPROGRAM
			#pragma target 5.0
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			// Particle's data
			struct Particle
			{
				float3 position;
				float3 velocity;
			};
			
			// Pixel shader input
			struct PS_INPUT
			{
				float4 position : SV_POSITION;
				float4 color : COLOR;
			};
			
			// Particle's data, shared with the compute shader
			StructuredBuffer<Particle> particleBuffer;
			
			// Properties variables
			uniform float4 _Tint;
			uniform float _Randomness;
			
			// Vertex shader
			PS_INPUT vert(uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID)
			{
				PS_INPUT o = (PS_INPUT)0;

				// Color
				float speed = length(particleBuffer[instance_id].velocity);

				//float lerpValue = clamp(speed / _HighSpeedValue, 0.0f, 1.0f);
				//float lerpValue = fmod(speed, 1.01f);
				//o.color = lerp(_ColorLow, _ColorHigh, lerpValue);

				float4 c = _Tint;

				c.r *= 1.0 - _Randomness;
				c.g *= 1.0 - _Randomness;
				c.b *= 1.0 - _Randomness;

				c.r += fmod(abs(particleBuffer[instance_id].velocity.x), _Randomness);
				c.g += fmod(abs(particleBuffer[instance_id].velocity.y), _Randomness);
				c.b += fmod(abs(particleBuffer[instance_id].velocity.z), _Randomness);

				c.r = min(c.r, 1.0);
				c.g = min(c.g, 1.0);
				c.b = min(c.b, 1.0);
				c.a = 1;
				o.color = c;

				// Position
				o.position = UnityObjectToClipPos(float4(particleBuffer[instance_id].position, 1.0f));

				return o;
			}

			// Pixel shader
			float4 frag(PS_INPUT i) : COLOR
			{
				return i.color;
			}
			
			ENDCG
		}
	}

	Fallback Off
}
