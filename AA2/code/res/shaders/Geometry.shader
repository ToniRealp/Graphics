#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 3) out;

uniform mat4 projection;

void main()
{
	vec4 position = gl_in[0].gl_Position;
	gl_Position = projection * position;
	EmitVertex();

	gl_Position = projection * (position + vec4(1.0, 0.0, 0.0, 1.0));
	EmitVertex();

	gl_Position = projection * (position + vec4(0.0, -1.0, 0.0, 1.0));
	EmitVertex();

	EndPrimitive();
}