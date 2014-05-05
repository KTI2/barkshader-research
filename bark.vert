#version 330 compatibility

uniform float uLightX, uLightY, uLightZ;
uniform float uKa, uKd, uKs;
uniform vec4  uColor;
uniform vec4  uSpecularColor;
uniform float uShininess;

uniform float divisions;

const float radius = 4.0;
const float pi = 3.1415;

flat out vec4 tmpColor;
flat out float useColor;

flat out vec3 vNs;
flat out vec3 vLs;
flat out vec3 vEs;
flat out vec3 vPVs;

void main( )
{
	useColor = 0.0;
	vec4 tmpVert = gl_Vertex;
	
	float theta = atan(gl_Vertex.x, gl_Vertex.y);
	
	float thetaDivision = floor(divisions/pi*theta);
	
	if(mod(thetaDivision, 2) == 0)
	{
		tmpColor = vec4(1.0, 1.0, 1.0, 1.0);
		useColor = 1.0;
	}
	
	vec4 ECposition = uModelViewMatrix * gl_Vertex;
	vec3 eyeLightPosition = vec3( uLightX, uLightY, uLightZ );

	vNs = normalize( uNormalMatrix * aNormal );	// surface normal vector
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

	gl_Position = uModelViewProjectionMatrix * tmpVert;
}
