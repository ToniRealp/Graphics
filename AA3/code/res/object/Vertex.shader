#version 330

in vec3 in_Position;
in vec3 in_Normal;
in vec2 in_UVs;
out vec4 vert_Normal;
out vec4 fragPos;
out vec2 uvs;

uniform mat4 model;
uniform mat4 view;
uniform mat4 mvp;

void main()
{
	gl_Position = mvp * vec4(in_Position, 1.0);
	fragPos = view * model * vec4(in_Position, 1.0);
	vert_Normal = view * model * vec4(in_Normal, 0.0);
	uvs = in_UVs;
}