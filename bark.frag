#version 330 compatibility

uniform float uKa, uKd, uKs;
uniform vec4  uColor;

flat in vec2 vST;

flat in vec3 vNs;
flat in vec3 vLs;
flat in vec3 vEs;

void main( )
{
	vec3 Normal;
	vec3 Light;
	vec3 Eye;

	Normal = normalize(vNs);
	Light =  normalize(vLs);
	Eye =    normalize(vEs);

	vec4 ambient = uKa * uColor;

	float d = max( dot(Normal,Light), 0. );
	vec4 diffuse = uKd * d * uColor;

	gl_FragColor = vec4( ambient.rgb + diffuse.rgb, 1. );
}
