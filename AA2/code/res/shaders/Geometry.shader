#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 96) out;

uniform mat4 projection;
uniform mat4 view;

float h = 1.0f;
float delta = 0.25f;

void create_face(vec4 v1, vec4 v2, vec4 v3)
{
	gl_Position = projection * view * v1;
	EmitVertex();

	gl_Position = projection * view *  v2;
	EmitVertex();

	gl_Position = projection * view *  v3;
	EmitVertex();

	EndPrimitive();
}

void emit_hexagon(vec4 v1, vec4 v2, vec4 v3)
{
	vec4 v12 = v2 - v1;
	vec4 v23 = v3 - v2;
	vec4 v31 = v1 - v3;

	vec4 vf1 = v1 + v12 * delta;
	vec4 vf2 = v1 + v12 * (1 - delta);
	vec4 vf3 = v2 + v23 * delta;
	vec4 vf4 = v2 + v23 * (1 - delta);
	vec4 vf5 = v3 + v31 * delta;
	vec4 vf6 = v3 + v31 * (1 - delta);

	create_face(vf1, vf2, vf3);
	create_face(vf1, vf3, vf4);
	create_face(vf1, vf4, vf5);
	create_face(vf1, vf5, vf6);
}

void main()
{
	vec4 center = gl_in[0].gl_Position;

	vec4 top_vertex = (center + vec4(0.0, 1.0, 0.0, 0.0) * h);
	vec4 bot_vertex = (center + vec4(0.0, -1.0, 0.0, 0.0) * h);

	vec4 back_left_vertex = (center + vec4(-1.0, 0.0, -1.0, 0.0) * h);
	vec4 back_right_vertex = (center + vec4(1.0, 0.0, -1.0, 0.0) * h);

	vec4 front_left_vertex = (center + vec4(-1.0, 0.0, 1.0, 0.0) * h);
	vec4 front_right_vertex = (center + vec4(1.0, 0.0, 1.0, 0.0) * h);

	emit_hexagon(top_vertex, back_right_vertex, back_left_vertex);
	emit_hexagon(top_vertex, front_left_vertex, front_right_vertex);
	emit_hexagon(top_vertex, back_left_vertex, front_left_vertex);
	emit_hexagon(top_vertex, front_right_vertex, back_right_vertex);
	emit_hexagon(bot_vertex, back_left_vertex, back_right_vertex);
	emit_hexagon(bot_vertex, front_right_vertex, front_left_vertex);
	emit_hexagon(bot_vertex, front_left_vertex, back_left_vertex);
	emit_hexagon(bot_vertex, back_right_vertex, front_right_vertex);
}