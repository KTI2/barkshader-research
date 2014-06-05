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

const int cylinderS = 512;
const int cylinderT = 512;
const float radius = 1.0;
const float height = 2.0;

const float pi = 3.14159;

flat out vec2 vST;

//Lighting vectors for fragment shader
flat out vec3 vNs;
flat out vec3 vLs;
flat out vec3 vEs;
flat out vec3 vPVs;

float getNoise(vec4 point) {
	vec4  nv  = texture3D( Noise3, uNoiseFreq * point.xyz );
	float n = nv.r + nv.g + nv.b + nv.a;	// 1. -> 3.
	n = ( n - 2. );				// -1. -> 1.
	return uNoiseMag * n;
}

//Converts a point to new bark form
vec4 convertPoint(vec4 point) {
	float chunkSize = 1.0/floor(divisions);
	float fracts = fract(vST.s/chunkSize);
	
	//Chunk to raise
	if(fracts < barkRatio)
	{	
		point.x*= barkHeight;
		point.z*= barkHeight;
	}
	
	float delta = getNoise(point);
	
	//Add noise to vertices
	point.x*= 1+delta;
	point.z*= 1+delta;
	
	return point;
}

void main()
{
	vec4 tmpVert = gl_Vertex;
	vST = gl_MultiTexCoord0.st;
	
	float theta = atan(gl_Vertex.x, gl_Vertex.z);
	
	//Get the up vector
	vec4 upVector = tmpVert;
	
	if(upVector.y >= 2.0) {
		upVector.x = 0.0;
		upVector.z = 0.0;
	} else {
		upVector.y += (1.0/cylinderT);
		upVector = convertPoint(upVector);
	}
	
	//Get the right vector
	vec4 rightVector = tmpVert;
	float thetaR = theta + 2*pi/cylinderS;
	
	rightVector.x = radius*sin(thetaR);
	rightVector.z = radius*cos(thetaR);
	rightVector = convertPoint(rightVector);
	
	vec3 newNormal = cross(upVector.xyz, rightVector.xyz);
	
	//Get current point
	tmpVert = convertPoint(tmpVert);
	
	vec4 ECposition = gl_ModelViewMatrix * tmpVert;
	vec3 eyeLightPosition = vec3( uLightX, uLightY, uLightZ );

	vNs = newNormal;
	
	//vNs = gl_NormalMatrix * gl_Normal;	// surface normal vector
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
