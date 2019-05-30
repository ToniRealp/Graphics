#version 330

layout(location = 0) in vec3 in_Position;
layout(location = 1) in vec3 in_Normal;
layout(location = 2) in vec2 in_UVs;

out vec4 vNormal;
out vec2 vUvs;
out vec4 vFragPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 mvp;

void main()
{
	gl_Position = mvp * vec4(in_Position, 1.0);
	vNormal = view * model * vec4(in_Normal, 0.0);

	vUvs = in_UVs;
	vFragPos = view * model * vec4(in_Position, 1.0);
}