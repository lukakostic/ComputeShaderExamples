// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tinted"
{
	Properties
	{
		_Tint("Tint", Color) = (1, 1, 1, 1)
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
		float lifetime;
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

	// Vertex shader
	PS_INPUT vert(uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID)
	{
		PS_INPUT o = (PS_INPUT)0;

		o.color = _Tint;

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
