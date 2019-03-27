#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 24) out;

uniform mat4 projection;
uniform mat4 view;

float h = 1.0f;

void create_face(vec4 v1, vec4 v2, vec4 v3)
{
	gl_Position = v1;
	EmitVertex();

	gl_Position = v2;
	EmitVertex();

	gl_Position = v3;
	EmitVertex();

	EndPrimitive();
}

void main()
{
	vec4 center = gl_in[0].gl_Position;

	vec4 top_vertex = projection * view * (center + vec4(0.0, 1.0, 0.0, 0.0) * h);
	vec4 bot_vertex = projection * view * (center + vec4(0.0, -1.0, 0.0, 0.0) * h);

	vec4 back_left_vertex = projection * view * (center + vec4(-1.0, 0.0, -1.0, 0.0) * (h / 2));
	vec4 back_right_vertex = projection * view * (center + vec4(1.0, 0.0, -1.0, 0.0) * (h / 2));

	vec4 front_left_vertex = projection * view * (center + vec4(-1.0, 0.0, 1.0, 0.0) * (h / 2));
	vec4 front_right_vertex = projection * view * (center + vec4(1.0, 0.0, 1.0, 0.0) * (h / 2));


	create_face(top_vertex, back_right_vertex, back_left_vertex);
	create_face(top_vertex, front_left_vertex, front_right_vertex);
	create_face(top_vertex, back_left_vertex, front_left_vertex);
	create_face(top_vertex, front_right_vertex, back_right_vertex);

	create_face(bot_vertex, back_left_vertex, back_right_vertex);
	create_face(bot_vertex, front_right_vertex, front_left_vertex);
	create_face(bot_vertex, front_left_vertex, back_left_vertex);
	create_face(bot_vertex, back_right_vertex, front_right_vertex);
}