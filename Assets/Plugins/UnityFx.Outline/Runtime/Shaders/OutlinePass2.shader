﻿// Copyright (C) 2019 Alexander Bogarsukov. All rights reserved.
// See the LICENSE.md file in the project root for more information.

// Renders outline based on a texture produces by 'UnityF/Outline/RenderColor' output.
// Modified version of 'Custom/Post Outline' shader taken from https://willweissman.wordpress.com/tutorials/shaders/unity-shaderlab-object-outlines/.
Shader "UnityFx/Outline/VPassBlend"
{
	Properties
	{
		_Color("Outline color", Color) = (1, 0, 0, 1)
		_Width("Outline thickness (in pixels)", Range(1, 32)) = 5
		[KeywordEnum(Solid, Blurred)] _Mode("Outline rendering mode", Float) = 0
	}

	SubShader
	{
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM

			#pragma multi_compile _MODE_SOLID _MODE_BLURRED
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MaskTex;
			float2 _MaskTex_TexelSize;
			sampler2D _HPassTex;
			float2 _HPassTex_TexelSize;
			float4 _Color;
			int _Width;

			struct v2f
			{
				float4 pos : POSITION;
				float2 uvs : TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uvs = ComputeScreenPos(o.pos);

				return o;
			}

			half4 frag(v2f i) : COLOR
			{
				if (tex2D(_MaskTex, i.uvs.xy).r > 0)
				{
					discard;
				}

				int n = _Width;

				float TX_y = _HPassTex_TexelSize.y;
				float intensity;
				float n2 = (float)n / 2;

				for (int k = 0; k < n; k += 1)
				{
#if _MODE_BLURRED
					intensity += tex2D(_HPassTex, i.uvs.xy + float2(0, (k - n2) * TX_y)).r / n;
#else
					intensity += tex2D(_HPassTex, i.uvs.xy + float2(0, (k - n2) * TX_y)).r;
#endif
				}

#if _MODE_BLURRED
				return half4(_Color.rgb, _Color.a * intensity * 2);
#else
				return _Color * intensity;
#endif
			}

			ENDCG
		}
	}
}