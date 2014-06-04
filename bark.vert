#version 330 compatibility

//Lighting
uniform float uLightX, uLightY, uLightZ;
uniform float uKa, uKd, uKs;
uniform vec4  uColor;
uniform vec4  uSpecularColor;
uniform float uShininess;

//Noise
uniform float uNoiseMag;
uniform float uNoiseFreq;
uniform sampler3D Noise3;

uniform float divisions;
uniform float barkRatio;
uniform float barkHeight;

const float pi = 3.14159;

flat out vec2 vST;

//Lighting vectors for fragment shader
flat out vec3 vNs;
flat out vec3 vLs;
flat out vec3 vEs;
flat out vec3 vPVs;

void main( )
{
	vec4 tmpVert = gl_Vertex;
	vST = gl_MultiTexCoord0.st;
	
	//Noise
	vec4  nv  = texture3D( Noise3, uNoiseFreq * tmpVert.xyz );
	float n = nv.r + nv.g + nv.b + nv.a;	// 1. -> 3.
	n = ( n - 2. );				// -1. -> 1.
	float delta = uNoiseMag * n;
	
	float chunkSize = 1.0/floor(divisions);
	
	if(fract(vST.s/ chunkSize) < barkRatio)
	{
		tmpVert.x*= barkHeight;
		tmpVert.z*= barkHeight;
	}
	
	//Add noise to vertices
	tmpVert.x*= 1+delta;
	tmpVert.z*= 1+delta;
	
	vec4 ECposition = gl_ModelViewMatrix * tmpVert;
	vec3 eyeLightPosition = vec3( uLightX, uLightY, uLightZ );

	vNs = normalize( gl_NormalMatrix * gl_Normal );	// surface normal vector
	vLs = eyeLightPosition - ECposition.xyz;		// vector from the point to the light
	vEs = vec3( 0., 0., 0. ) - ECposition.xyz;		// vector from the point

	vec3 Normal;
	vec3 Light;
	vec3 Eye;

	Normal = normalize(vNs);
	Light =  normalize(vLs);
	Eye =    normalize(vEs);

	vec4 ambient = uKa * uColor;

	float d = max( dot(Normal,Light), 0. );
	vec4 diffuse = uKd * d * uColor;

	float s = 0.;
	if( dot(Normal,Light) > 0. )		// only do specular if the light can see the point
	{
		vec3 ref = normalize( 2. * Normal * dot(Normal,Light) - Light );
		s = pow( max( dot(Eye,ref),0. ), uShininess );
	}
	vec4 specular = uKs * s * uSpecularColor;

	vPVs = ambient.rgb + diffuse.rgb + specular.rgb;

	gl_Position = gl_ModelViewProjectionMatrix * tmpVert;
}
