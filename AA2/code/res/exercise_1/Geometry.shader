#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 82) out;

out vec4 face_color;

uniform mat4 projection;
uniform mat4 view;


float h = 1.0f;
float delta = 0.3f;

vec4 red = vec4(1.0, 0.0, 0.0, 1.0);
vec4 blue = vec4(0.0, 0.0, 1.0, 1.0);


struct Quad { vec3 vertices[4]; };
struct Hexagon { vec3 vertices[6]; };



void emit_vertex(vec3 vertex, vec4 color)
{
	gl_Position = projection * view * vec4(vertex, 1.0);
	face_color = color;
	EmitVertex();
}

Quad emit_quad(vec3 v1, vec3 v2, vec3 v3, vec3 v4, vec3 v5, vec4 color)
{
	Quad quad = Quad(vec3[4](v1 + (v2 - v1) * delta, v1 + (v3 - v1) * delta, v1 + (v4 - v1) * delta, v1 + (v5 - v1) * delta));

	emit_vertex(quad.vertices[0], color);
	emit_vertex(quad.vertices[1], color);
	emit_vertex(quad.vertices[3], color);
	emit_vertex(quad.vertices[2], color);

	EndPrimitive();

	return quad;
};

void emit_hexagon(Hexagon hex, vec4 color)
{
	emit_vertex(hex.vertices[1], color);
	emit_vertex(hex.vertices[2], color);
	emit_vertex(hex.vertices[0], color);
	emit_vertex(hex.vertices[3], color);
	emit_vertex(hex.vertices[5], color);
	emit_vertex(hex.vertices[4], color);

	EndPrimitive();
}

void main()
{
	vec3 center = gl_in[0].gl_Position.xyz;

	vec3 top_vertex = center + vec3(0.0, 1.0, 0.0) * h;
	vec3 bot_vertex = center + vec3(0.0, -1.0, 0.0) * h;

	vec3 back_left_vertex = center + vec3(-1.0, 0.0, -1.0) * h;
	vec3 back_right_vertex = center + vec3(1.0, 0.0, -1.0) * h;

	vec3 front_left_vertex = center + vec3(-1.0, 0.0, 1.0) * h;
	vec3 front_right_vertex = center + vec3(1.0, 0.0, 1.0) * h;



	Quad quad_top = emit_quad(top_vertex, back_right_vertex, back_left_vertex, front_left_vertex, front_right_vertex, red);
	Quad quad_bot = emit_quad(bot_vertex, front_right_vertex, front_left_vertex, back_left_vertex, back_right_vertex, red);

	Quad quad_front_right = emit_quad(front_right_vertex, back_right_vertex, top_vertex, front_left_vertex, bot_vertex, red);
	Quad quad_front_left = emit_quad(front_left_vertex, front_right_vertex, top_vertex, back_left_vertex, bot_vertex, red);

	Quad quad_back_right = emit_quad(back_right_vertex, back_left_vertex, top_vertex, front_right_vertex, bot_vertex, red);
	Quad quad_back_left = emit_quad(back_left_vertex, front_left_vertex, top_vertex, back_right_vertex, bot_vertex, red);

	Hexagon hex_top_front = Hexagon(vec3[6](quad_top.vertices[2], quad_front_left.vertices[1], quad_front_left.vertices[0], quad_front_right.vertices[2], quad_front_right.vertices[1], quad_top.vertices[3]));
	Hexagon hex_top_right = Hexagon(vec3[6](quad_top.vertices[3], quad_front_right.vertices[1], quad_front_right.vertices[0], quad_back_right.vertices[2], quad_back_right.vertices[1], quad_top.vertices[0]));
	Hexagon hex_top_back = Hexagon(vec3[6](quad_top.vertices[0], quad_back_right.vertices[1], quad_back_right.vertices[0], quad_back_left.vertices[2], quad_back_left.vertices[1], quad_top.vertices[1]));
	Hexagon hex_top_left = Hexagon(vec3[6](quad_top.vertices[1], quad_back_left.vertices[1], quad_back_left.vertices[0], quad_front_left.vertices[2], quad_front_left.vertices[1], quad_top.vertices[2]));

	Hexagon hex_bot_front = Hexagon(vec3[6](quad_bot.vertices[0], quad_front_right.vertices[3], quad_front_right.vertices[2], quad_front_left.vertices[0], quad_front_left.vertices[3], quad_bot.vertices[1]));
	Hexagon hex_bot_right = Hexagon(vec3[6](quad_bot.vertices[3], quad_back_right.vertices[3], quad_back_right.vertices[2], quad_front_right.vertices[0], quad_front_right.vertices[3], quad_bot.vertices[0]));
	Hexagon hex_bot_back = Hexagon(vec3[6](quad_bot.vertices[2], quad_back_left.vertices[3], quad_back_left.vertices[2], quad_back_right.vertices[0], quad_back_right.vertices[3], quad_bot.vertices[3]));
	Hexagon hex_bot_left = Hexagon(vec3[6](quad_bot.vertices[1], quad_front_left.vertices[3], quad_front_left.vertices[2], quad_back_left.vertices[0], quad_back_left.vertices[3], quad_bot.vertices[2]));

	emit_hexagon(hex_top_front, blue);
	emit_hexagon(hex_top_right, blue);
	emit_hexagon(hex_top_back, blue);
	emit_hexagon(hex_top_left, blue);
	
	emit_hexagon(hex_bot_front, blue);
	emit_hexagon(hex_bot_right, blue);
	emit_hexagon(hex_bot_back, blue);
	emit_hexagon(hex_bot_left, blue);	
}