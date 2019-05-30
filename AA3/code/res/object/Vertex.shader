#version 330

in vec3 in_Position;
in vec3 in_Normal;
in vec2 in_UVs;
out vec4 vNormal;
out vec2 vUvs;

uniform mat4 model;
uniform mat4 view;
uniform mat4 mvp;

void main()
{
	gl_Position = mvp * vec4(in_Position, 1.0);
	vNormal = mvp * vec4(in_Normal, 0.0);
	vUvs = in_UVs;
}