Shader "Custom/SmoothLifeShader"

// based on <https://git.io/vz29Q>
// Copied from davidar's Smooth Life Gliders (https://www.shadertoy.com/view/Msy3RD)
//
// ---------------------------------------------
// SmoothLife (discrete time stepping 2D)

{
	Properties
	{
		_PastTex ("Past texture", 2D) = "white" {}
		_Resolution ("Size",Vector) = (0, 0, 0, 0)
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _PastTex;
			float4 _Resolution;

			float ra = 12.0;       // outer radius
			float rr = 3.0;       // ratio of radii
			float b = 1.0;        // smoothing border width
			float b1 = 0.305;      // birth1
			float b2 = 0.443;      // birth2
			float d1 = 0.556;     // survival1
			float d2 = 0.814;      // survival2
			float sn = 0.028;     // sigmoid width for outer fullness
			float sm = 0.147;     // sigmoid width for inner fullness
			float dt = .089;      // dt per frame


			float smooth_s(float x, float a, float ea)
			{
				return 1.0 / (1.0 + exp((a - x) * 4.0 / ea));
			}

			float sigmoid_ab(float x, float a, float b)
			{
				return smooth_s(x, a, sn) * (1.0 - smooth_s(x, b, sn));
			}

			float sigmoid_mix(float x, float y, float m)
			{
				float sigmoidM = smooth_s(m, 0.5, sm);
				return x * (1.0 - sigmoidM) + y * sigmoidM;
			}

			// the transition function
			// (n = outer fullness, m = inner fullness)
			float snm(float n, float m)
			{
				return sigmoid_mix(sigmoid_ab(n, b1, b2), sigmoid_ab(n, d1, d2), m);
			}

			float ramp_step(float x, float a, float ea)
			{
				return clamp((a - x) / ea + 0.5, 0.0, 1.0);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float2 invResolution = 1.0f /_Resolution.xy;

				if (distance(i.uv, float2(.5 + cos(_Time.y * 1.5) * .2,.5 + sin(_Time.y) * .2)) < .025)
				{
					return 1.;
				}

				/*
				
				float accu = 0;
				float4 pos;
				float lod = 100;
				pos = float4(i.uv + float2(-1, -1) / _Resolution.xy, 0, lod);
				accu += tex2Dlod(_PastTex, pos).a;
				pos = float4(i.uv + float2( 0, -1) / _Resolution.xy, 0, lod);
				accu += tex2Dlod(_PastTex, pos).a;
				pos = float4(i.uv + float2( 1, -1) / _Resolution.xy, 0, lod);
				accu += tex2Dlod(_PastTex, pos).a;
				pos = float4(i.uv + float2(-1,  1) / _Resolution.xy, 0, lod);
				accu += tex2Dlod(_PastTex, pos).a;
				pos = float4(i.uv + float2( 0,  1) / _Resolution.xy, 0, lod);
				accu += tex2Dlod(_PastTex, pos).a;
				pos = float4(i.uv + float2( 1,  1) / _Resolution.xy, 0, lod);
				accu += tex2Dlod(_PastTex, pos).a;
				pos = float4(i.uv + float2(-1,  0) / _Resolution.xy, 0, lod);
				accu += tex2Dlod(_PastTex, pos).a;
				pos = float4(i.uv + float2( 1,  0) / _Resolution.xy, 0, lod);
				accu += tex2Dlod(_PastTex, pos).a;

				float state = tex2Dlod(_PastTex, float4(i.uv, 0 , lod)).a;
				if (state > .5 && accu == 2. || accu == 3. )
				{
					state = 1.;
				}
				else
				{
					state = 0.;
				}
				return float4(state, state, state, state);
				/*/
				
				// inner radius:
				const float rb = ra / rr;
				// area of annulus:
				const float PI = 3.14159265358979;
				const float AREA_OUTER = PI * (ra*ra - rb*rb);
				const float AREA_INNER = PI * rb * rb;

				float lodLevel = 10000.;

				// how full are the annulus and inner disk?
				float outf = 0.0, inf = 0.0;
				for (int dx = -ra; dx <= ra; ++dx) 
				{
					for (int dy = -ra; dy <= ra; ++dy)
					{
						float r = sqrt(float(dx*dx + dy*dy));
						float2 txy = (i.uv + float2(dx, dy) / _Resolution.xy) % 1.;
						float4 txyzw = float4(txy, 0., lodLevel);
						float val = tex2Dlod(_PastTex, txyzw).r;
						float inner_kernel = ramp_step(r, rb, b);
						float outer_kernel = ramp_step(r, ra, b) * (1.0 - inner_kernel);
						inf += val * inner_kernel;
						outf += val * outer_kernel;
					}
				}
				outf /= AREA_OUTER; // normalize by area
				inf /= AREA_INNER; // normalize by area
				float4 prevState = tex2Dlod(_PastTex, float4(i.uv, 0, lodLevel));
				float s = prevState.r;
				float deriv = 2.0 * snm(outf, inf) - 1.0;
				
				s = clamp(s + (deriv * dt), 0.0, 1.0);  // Apply delta to state
				

				return float4(s, inf, outf, 0.);
				// */
			}
			ENDCG
		}
	}
}
