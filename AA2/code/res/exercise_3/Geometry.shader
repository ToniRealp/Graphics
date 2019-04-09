#version 330 core

layout(points) in;
layout(points, max_vertices = 128) out;


uniform mat4 projection;
uniform mat4 view;


void main()
{
	vec3 center = gl_in[0].gl_Position.xyz;

	vec3 vertices[9];

	int i = 0;
	for (int x = -1; x < 2; ++x)
	{
		for (int y = -1; y < 2; ++y)
		{
			vertices[i] = vec3(center.x + x * 2, center.y + y * 2, 0);
			gl_Position = projection * view * vec4(vertices[i], 1.0);
			EmitVertex();
			EndPrimitive();
			i++;
		}
	}
}