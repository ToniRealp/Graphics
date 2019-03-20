#version 330 core

layout(points) in;
layout(triangles, max_vertices = 3) out;


void main()
{
	vec4 position = gl_in[0].gl_Position;
	gl_Position = position;
	EmitVertex();

	gl_Position = position + vec4(1.0, 0.0, 0.0, 1.0);
	EmitVertex();

	gl_Position = position + vec4(0.0, -1.0, 0.0, 1.0);
	EmitVertex();

	EndPrimitive();
}