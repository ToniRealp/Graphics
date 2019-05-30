#version 330

layout(triangles) in;
layout(triangle_strip, max_vertices = 15) out;

in vec4 vNormal[];
in vec2 vUvs[];

out vec2 gUvs;
out vec4 gNormal;
out vec4 fragPos;

uniform mat4 projection;
uniform float time;
uniform int useStencil;
float offset = 0.5;

void main() 
{
	for (int i = 0; i < 3; ++i) 
	{
		vec4 vert = gl_in[i].gl_Position;

		if (useStencil == 1) 
		{
			vert += vNormal[i] * 0.05;
			vec4 va = gl_in[0].gl_Position;
			vec4 vb = gl_in[1].gl_Position;
			vec4 vc = gl_in[2].gl_Position;
			vec4 cent = (va + vb + vc) / 3.0;
			vert += (gl_in[i].gl_Position - cent) * 0.5;
		}

		gl_Position = projection * vert;
		gNormal = vNormal[i];
		gUvs = uvs[i];
		EmitVertex();
	}
	EndPrimitive();
}