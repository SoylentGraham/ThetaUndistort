Shader "NewChromantics/ThetaUndistort"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		
		Left_CropLeft("Left_CropLeft", Range(0,1) ) = 0.209
		Left_CropRight("Left_CropRight", Range(0,1) ) = 0.91
		Left_CropTop("Left_CropTop", Range(0,1) ) = 0.511
		Left_CropBottom("Left_CropBottom", Range(0,1) ) = 0.947
		Left_HorzCenter("Left_HorzCenter", Range(-0.5,0.5) ) = 0
		Left_VertCenter("Left_VertCenter", Range(-0.5,0.5) ) = 0.042

		Right_CropLeft("Right_CropLeft", Range(0,1) ) = 0.035
		Right_CropRight("Right_CropRight", Range(0,1) ) = 0.87
		Right_CropTop("Right_CropTop", Range(0,1) ) = 0.526
		Right_CropBottom("Right_CropBottom", Range(0,1) ) = 0.989
		Right_HorzCenter("Right_HorzCenter", Range(-0.5,0.5) ) = 0
		Right_VertCenter("Right_VertCenter", Range(-0.5,0.5) ) = 0
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float Left_CropLeft;
			float Left_CropTop;
			float Left_CropRight;
			float Left_CropBottom;
			float Left_HorzCenter;
			float Left_VertCenter;

			float Right_CropLeft;
			float Right_CropTop;
			float Right_CropRight;
			float Right_CropBottom;
			float Right_HorzCenter;
			float Right_VertCenter;
					
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			
			
			float2 GetSphereUv(float2 TargetUv)
			{				
				float theta,phi,r;
				float3 psph;
	
				float FOV = 3.141592654; // FOV of the fisheye, eg: 180 degrees
				
				#define PI 3.14159265
				
				float2 PolarUv = TargetUv;
			
				//	gr: this seems wrong	
				PolarUv.x += 0.5;
				PolarUv.x /= 2;
			
				// Polar angles
				theta = lerp( -PI, PI, PolarUv.x ); // -pi to pi
				phi = lerp( -PI/2, PI/2, PolarUv.y );	// -pi/2 to pi/2

				// Vector in 3D space
				psph.x = cos(phi) * sin(theta);
				psph.y = cos(phi) * cos(theta);
				psph.z = sin(phi);
				
				
				// Calculate fisheye angle and radius
				theta = atan2(psph.z,psph.x);
				phi = atan2(sqrt(psph.x*psph.x+psph.z*psph.z),psph.y);
				r = phi / FOV; 

				// Pixel in fisheye space
				float2 pfish;
				pfish.x = 0.5 + r * cos(theta);
				pfish.y = 0.5 + r * sin(theta);
				
				return pfish;
			}


			float2 Rotate90(float2 pos)
			{				
				return float2( 1 - pos.y, pos.x );
			}
			
			float2 Rotate180(float2 pos)
			{
				return float2( 1-pos.x, 1-pos.y );
			}
			
			float Range(float Min,float Max,float Value)
			{
				return (Value - Min) / ( Max - Min );
			}


			float2 CropUv(float2 uv,float4 CropRect)
			{
				float u = lerp( CropRect.x, CropRect.z, uv.x );
				float v = lerp( CropRect.y, CropRect.w, uv.y );
				return float2( u, v );
			}

			float2 CropUv_Left(float2 uv)
			{
				uv += float2( Left_HorzCenter, Left_VertCenter );
				uv = CropUv( uv, float4( Left_CropLeft, Left_CropTop, Left_CropRight, Left_CropBottom ) );
				uv = Rotate90( uv );
				return uv;
			}
			float2 CropUv_Right(float2 uv)
			{
				uv += float2( Right_HorzCenter, Right_VertCenter );
				uv = CropUv( uv, float4( Right_CropLeft,Right_CropTop, Right_CropRight, Right_CropBottom ) );
				uv = Rotate90( uv );
				uv = Rotate90( uv );
				uv = Rotate90( uv );
				return uv;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float2 Sphereuv;
				if ( i.uv.x < 0.5f )
				{
					Sphereuv = float2( i.uv.x * 2, i.uv.y );
					Sphereuv = GetSphereUv( Sphereuv );
					Sphereuv = CropUv_Left( Sphereuv );

				}
				else
				{
					Sphereuv = float2( (i.uv.x-0.5) * 2, i.uv.y );
					Sphereuv = GetSphereUv( Sphereuv );
					Sphereuv = CropUv_Right( Sphereuv );
				}

				if ( Sphereuv.x < 0 || Sphereuv.x > 1 || Sphereuv.y < 0 || Sphereuv.y > 1 )
					return float4( 0,0,1,1 );
					
				float4 rgba = float4( 0, 0, 0, 1);
				rgba += tex2D(_MainTex, Sphereuv );
				return rgba;
			}
			ENDCG
		}
	}
}
