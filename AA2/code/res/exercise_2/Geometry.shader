//
// GEOMETRY SHADER : EXERCISE 2
//

#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 1000) out;

uniform mat4 projection;
uniform mat4 view;

uniform float alpha;


float h = 1.0f;
float delta = 0.3f;

out vec3 face_color;

vec3 red = vec3(1.0, 0.0, 0.0);
vec3 blue = vec3(0.0, 0.0, 1.0);
vec3 green = vec3(0.0, 1.0, 0.0);

struct Quad { vec3 vertices[4]; };
struct Hexagon { vec3 vertices[6]; };

void emit_vertex(vec3 vertex)
{
	gl_Position = projection * view * vec4(vertex, 1.0);
	EmitVertex();
}

void emit_hexagon(Hexagon hex)
{
	face_color = blue;
	emit_vertex(hex.vertices[1]);
	emit_vertex(hex.vertices[2]);
	emit_vertex(hex.vertices[0]);
	emit_vertex(hex.vertices[3]);
	emit_vertex(hex.vertices[5]);
	emit_vertex(hex.vertices[4]);

	EndPrimitive();
}

void emit_octagon(vec3 v1, vec3 v2, vec3 v3, vec3 v4, vec3 v5, vec3 v6, vec3 v7, vec3 v8)
{
	face_color = green;
	emit_vertex(v2);
	emit_vertex(v3);
	emit_vertex(v1);
	emit_vertex(v4);
	emit_vertex(v8);
	emit_vertex(v5);
	emit_vertex(v7);
	emit_vertex(v6);

	EndPrimitive();
}

void emit_quad(vec3 v1, vec3 v2, vec3 v3, vec3 v4)
{
	face_color = red;
	emit_vertex(v1);
	emit_vertex(v2);
	emit_vertex(v3);
	emit_vertex(v4);

	EndPrimitive();
}


Quad get_quad(vec3 v1, vec3 v2, vec3 v3, vec3 v4, vec3 v5)
{
	Quad quad;
	quad.vertices[0] = v1 + (v2 - v1) * delta;
	quad.vertices[1] = v1 + (v3 - v1) * delta;
	quad.vertices[2] = v1 + (v4 - v1) * delta;
	quad.vertices[3] = v1 + (v5 - v1) * delta;

	return quad;
};

Hexagon get_hexagon(vec3 v1, vec3 v2, vec3 v3, vec3 v4, vec3 v5, vec3 v6)
{
	Hexagon hex;
	hex.vertices[0] = v1;
	hex.vertices[1] = v2;
	hex.vertices[2] = v3;
	hex.vertices[3] = v4;
	hex.vertices[4] = v5;
	hex.vertices[5] = v6;

	return hex;
}

vec3 find_baricenter(Hexagon hex)
{
	return (hex.vertices[0] + hex.vertices[3]) / 2;
}

void shrink(inout Hexagon hex)
{
	// Find hexagon center.
	vec3 hex_center = find_baricenter(hex);

	// Move the hexagon vertices by alpha.
	for (int i = 0; i < 6; i++)
	{
		vec3 dir = hex_center - hex.vertices[i];
		hex.vertices[i] = hex.vertices[i] + dir * alpha;
	}
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


	Quad quad_top = get_quad(top_vertex, back_right_vertex, back_left_vertex, front_left_vertex, front_right_vertex);
	Quad quad_bot = get_quad(bot_vertex, front_right_vertex, front_left_vertex, back_left_vertex, back_right_vertex);

	Quad quad_front_right = get_quad(front_right_vertex, back_right_vertex, top_vertex, front_left_vertex, bot_vertex);
	Quad quad_front_left = get_quad(front_left_vertex, front_right_vertex, top_vertex, back_left_vertex, bot_vertex);

	Quad quad_back_right = get_quad(back_right_vertex, back_left_vertex, top_vertex, front_right_vertex, bot_vertex);
	Quad quad_back_left = get_quad(back_left_vertex, front_left_vertex, top_vertex, back_right_vertex, bot_vertex);
	


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
	
	shrink(hex_top_front);
	shrink(hex_top_right);
	shrink(hex_top_left);
	shrink(hex_top_back);
	shrink(hex_bot_front);
	shrink(hex_bot_right);
	shrink(hex_bot_left);
	shrink(hex_bot_back);

	//Quads
	emit_quad(hex_top_front.vertices[5], hex_top_front.vertices[4], hex_top_right.vertices[0], hex_top_right.vertices[1]);
	emit_quad(hex_top_left.vertices[5], hex_top_left.vertices[4], hex_top_front.vertices[0], hex_top_front.vertices[1]);
	emit_quad(hex_top_right.vertices[5], hex_top_right.vertices[4], hex_top_back.vertices[0], hex_top_back.vertices[1]);
	emit_quad(hex_top_left.vertices[1], hex_top_left.vertices[0], hex_top_back.vertices[4], hex_top_back.vertices[5]);

	emit_quad(hex_bot_front.vertices[2], hex_top_front.vertices[3], hex_bot_front.vertices[3], hex_top_front.vertices[2]);
	emit_quad(hex_bot_right.vertices[2], hex_top_right.vertices[3], hex_bot_right.vertices[3], hex_top_right.vertices[2]);
	emit_quad(hex_bot_back.vertices[2], hex_top_back.vertices[3], hex_bot_back.vertices[3], hex_top_back.vertices[2]);
	emit_quad(hex_bot_left.vertices[2], hex_top_left.vertices[3], hex_bot_left.vertices[3], hex_top_left.vertices[2]);

	emit_quad(hex_bot_front.vertices[0], hex_bot_right.vertices[5], hex_bot_front.vertices[1], hex_bot_right.vertices[4]);
	emit_quad(hex_bot_right.vertices[0], hex_bot_back.vertices[5], hex_bot_right.vertices[1], hex_bot_back.vertices[4]);
	emit_quad(hex_bot_back.vertices[0], hex_bot_left.vertices[5], hex_bot_back.vertices[1], hex_bot_left.vertices[4]);
	emit_quad(hex_bot_left.vertices[0], hex_bot_front.vertices[5], hex_bot_left.vertices[1], hex_bot_front.vertices[4]);

	//Top Octagon
	emit_octagon(hex_top_front.vertices[0], hex_top_front.vertices[5], hex_top_right.vertices[0], hex_top_right.vertices[5],
		hex_top_back.vertices[0], hex_top_back.vertices[5], hex_top_left.vertices[0], hex_top_left.vertices[5]);

	//Side octagons
	emit_octagon(hex_bot_front.vertices[2], hex_bot_front.vertices[1], hex_bot_right.vertices[4], hex_bot_right.vertices[3],
		hex_top_right.vertices[2], hex_top_right.vertices[1], hex_top_front.vertices[4], hex_top_front.vertices[3]);
	emit_octagon(hex_bot_right.vertices[2], hex_bot_right.vertices[1], hex_bot_back.vertices[4], hex_bot_back.vertices[3],
		hex_top_back.vertices[2], hex_top_back.vertices[1], hex_top_right.vertices[4], hex_top_right.vertices[3]);
	emit_octagon(hex_bot_back.vertices[2], hex_bot_back.vertices[1], hex_bot_left.vertices[4], hex_bot_left.vertices[3],
		hex_top_left.vertices[2], hex_top_left.vertices[1], hex_top_back.vertices[4], hex_top_back.vertices[3]);
	emit_octagon(hex_bot_left.vertices[2], hex_bot_left.vertices[1], hex_bot_front.vertices[4], hex_bot_front.vertices[3],
		hex_top_front.vertices[2], hex_top_front.vertices[1], hex_top_left.vertices[4], hex_top_left.vertices[3]);

	//Bot octagon
	emit_octagon(hex_bot_front.vertices[0], hex_bot_front.vertices[5], hex_bot_left.vertices[0], hex_bot_left.vertices[5],
		hex_bot_back.vertices[0], hex_bot_back.vertices[5], hex_bot_right.vertices[0], hex_bot_right.vertices[5]);

	//Hexagons
	emit_hexagon(hex_top_front);
	emit_hexagon(hex_top_right);
	emit_hexagon(hex_top_back);
	emit_hexagon(hex_top_left);
	
	emit_hexagon(hex_bot_front);
	emit_hexagon(hex_bot_right);
	emit_hexagon(hex_bot_back);
	emit_hexagon(hex_bot_left);
}