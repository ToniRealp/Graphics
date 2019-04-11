#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 82) out;

out vec4 face_color;

uniform mat4 projection;
uniform mat4 view;


float h = 1.0f;
float delta = 0.3333333f;

vec4 hexagon_color = vec4(0.2, 0.4, 0.6, 1.0);
vec4 quad_color = vec4(0.114, 0.161, 0.318, 1.0);


struct Quad { vec3 vertices[4]; };
struct Hexagon { vec3 vertices[6]; };



void emit_vertex(vec3 vertex, vec4 color)
{
	gl_Position = projection * view * vec4(vertex, 1.0);
	face_color = color;
	EmitVertex();
}

Quad emit_quad(vec3 v1, vec3 v2, vec3 v3, vec3 v4, vec3 v5)
{
	Quad quad;
	quad.vertices[0] = v1 + (v2 - v1) * delta;
	quad.vertices[1] = v1 + (v3 - v1) * delta;
	quad.vertices[2] = v1 + (v4 - v1) * delta;
	quad.vertices[3] = v1 + (v5 - v1) * delta;

	emit_vertex(quad.vertices[0], quad_color);
	emit_vertex(quad.vertices[1], quad_color);
	emit_vertex(quad.vertices[3], quad_color);
	emit_vertex(quad.vertices[2], quad_color);

	EndPrimitive();

	return quad;
};

void emit_hexagon(Hexagon hex)
{
	emit_vertex(hex.vertices[1], hexagon_color);
	emit_vertex(hex.vertices[2], hexagon_color);
	emit_vertex(hex.vertices[0], hexagon_color);
	emit_vertex(hex.vertices[3], hexagon_color);
	emit_vertex(hex.vertices[5], hexagon_color);
	emit_vertex(hex.vertices[4], hexagon_color);

	EndPrimitive();
}

void main()
{
	vec3 center = gl_in[0].gl_Position.xyz;

	vec3 top_vertex = center + vec3(0.0, 1.0, 0.0) * h;
	vec3 bot_vertex = center + vec3(0.0, -1.0, 0.0) * h;

	vec3 back_left_vertex = center + vec3(-0.70, 0.0, -0.7) * h;
	vec3 back_right_vertex = center + vec3(0.70, 0.0, -0.7) * h;
															   
	vec3 front_left_vertex = center + vec3(-0.7, 0.0, 0.7) * h;
	vec3 front_right_vertex = center + vec3(0.7, 0.0, 0.7) * h;



	Quad quad_top = emit_quad(top_vertex, back_right_vertex, back_left_vertex, front_left_vertex, front_right_vertex);
	Quad quad_bot = emit_quad(bot_vertex, front_right_vertex, front_left_vertex, back_left_vertex, back_right_vertex);

	Quad quad_front_right = emit_quad(front_right_vertex, back_right_vertex, top_vertex, front_left_vertex, bot_vertex);
	Quad quad_front_left = emit_quad(front_left_vertex, front_right_vertex, top_vertex, back_left_vertex, bot_vertex);

	Quad quad_back_right = emit_quad(back_right_vertex, back_left_vertex, top_vertex, front_right_vertex, bot_vertex);
	Quad quad_back_left = emit_quad(back_left_vertex, front_left_vertex, top_vertex, back_right_vertex, bot_vertex);

	Hexagon hex_top_front;
	hex_top_front.vertices[0] = quad_top.vertices[2];
	hex_top_front.vertices[1] = quad_front_left.vertices[1];
	hex_top_front.vertices[2] = quad_front_left.vertices[0];
	hex_top_front.vertices[3] = quad_front_right.vertices[2];
	hex_top_front.vertices[4] = quad_front_right.vertices[1];
	hex_top_front.vertices[5] = quad_top.vertices[3];

	Hexagon hex_top_right;
	hex_top_right.vertices[0] = quad_top.vertices[3];
	hex_top_right.vertices[1] = quad_front_right.vertices[1];
	hex_top_right.vertices[2] = quad_front_right.vertices[0];
	hex_top_right.vertices[3] = quad_back_right.vertices[2];
	hex_top_right.vertices[4] = quad_back_right.vertices[1];
	hex_top_right.vertices[5] = quad_top.vertices[0];

	Hexagon hex_top_back;
	hex_top_back.vertices[0] = quad_top.vertices[0];
	hex_top_back.vertices[1] = quad_back_right.vertices[1];
	hex_top_back.vertices[2] = quad_back_right.vertices[0];
	hex_top_back.vertices[3] = quad_back_left.vertices[2];
	hex_top_back.vertices[4] = quad_back_left.vertices[1];
	hex_top_back.vertices[5] = quad_top.vertices[1];


	Hexagon hex_top_left;
	hex_top_left.vertices[0] = quad_top.vertices[1];
	hex_top_left.vertices[1] = quad_back_left.vertices[1];
	hex_top_left.vertices[2] = quad_back_left.vertices[0];
	hex_top_left.vertices[3] = quad_front_left.vertices[2];
	hex_top_left.vertices[4] = quad_front_left.vertices[1];
	hex_top_left.vertices[5] = quad_top.vertices[2];

	Hexagon hex_bot_front;
	hex_bot_front.vertices[0] = quad_bot.vertices[0];
	hex_bot_front.vertices[1] = quad_front_right.vertices[3];
	hex_bot_front.vertices[2] = quad_front_right.vertices[2];
	hex_bot_front.vertices[3] = quad_front_left.vertices[0];
	hex_bot_front.vertices[4] = quad_front_left.vertices[3];
	hex_bot_front.vertices[5] = quad_bot.vertices[1];

	Hexagon hex_bot_right;
	hex_bot_right.vertices[0] = quad_bot.vertices[3];
	hex_bot_right.vertices[1] = quad_back_right.vertices[3];
	hex_bot_right.vertices[2] = quad_back_right.vertices[2];
	hex_bot_right.vertices[3] = quad_front_right.vertices[0];
	hex_bot_right.vertices[4] = quad_front_right.vertices[3];
	hex_bot_right.vertices[5] = quad_bot.vertices[0];

	Hexagon hex_bot_back;
	hex_bot_back.vertices[0] = quad_bot.vertices[2];
	hex_bot_back.vertices[1] = quad_back_left.vertices[3];
	hex_bot_back.vertices[2] = quad_back_left.vertices[2];
	hex_bot_back.vertices[3] = quad_back_right.vertices[0];
	hex_bot_back.vertices[4] = quad_back_right.vertices[3];
	hex_bot_back.vertices[5] = quad_bot.vertices[3];


	Hexagon hex_bot_left;
	hex_bot_left.vertices[0] = quad_bot.vertices[1];
	hex_bot_left.vertices[1] = quad_front_left.vertices[3];
	hex_bot_left.vertices[2] = quad_front_left.vertices[2];
	hex_bot_left.vertices[3] = quad_back_left.vertices[0];
	hex_bot_left.vertices[4] = quad_back_left.vertices[3];
	hex_bot_left.vertices[5] = quad_bot.vertices[2];

	emit_hexagon(hex_top_front);
	emit_hexagon(hex_top_right);
	emit_hexagon(hex_top_back);
	emit_hexagon(hex_top_left);
	
	emit_hexagon(hex_bot_front);
	emit_hexagon(hex_bot_right);
	emit_hexagon(hex_bot_back);
	emit_hexagon(hex_bot_left);	
}