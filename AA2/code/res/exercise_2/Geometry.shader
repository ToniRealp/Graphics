//
// GEOMETRY SHADER : EXERCISE 2
//

#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 128) out;

out vec4 face_color;

uniform mat4 projection;
uniform mat4 view;

uniform float alpha;


float h = 1.0f;
float delta = 0.3f;


vec4 red = vec4(1.0, 0.0, 0.0, 1.0);
vec4 blue = vec4(0.0, 0.0, 1.0, 1.0);
vec4 green = vec4(0.0, 1.0, 0.0, 1.0);


struct Quad { vec3 vertices[4]; };
struct Hexagon { vec3 vertices[6]; };



void emit_vertex(vec3 vertex, vec4 color)
{
	gl_Position = projection * view * vec4(vertex, 1.0);
	face_color = color;
	EmitVertex();
}


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

void emit_octagon(vec3 v1, vec3 v2, vec3 v3, vec3 v4, vec3 v5, vec3 v6, vec3 v7, vec3 v8)
{
	emit_vertex(v2, green);
	emit_vertex(v3, green);
	emit_vertex(v1, green);
	emit_vertex(v4, green);
	emit_vertex(v8, green);
	emit_vertex(v5, green);
	emit_vertex(v7, green);
	emit_vertex(v6, green);

	EndPrimitive();
}

void emit_quad(vec3 v1, vec3 v2, vec3 v3, vec3 v4)
{
	emit_vertex(v1, red);
	emit_vertex(v2, red);
	emit_vertex(v3, red);
	emit_vertex(v4, red);

	EndPrimitive();
}


Quad get_quad(vec3 v1, vec3 v2, vec3 v3, vec3 v4, vec3 v5, vec4 color)
{
	Quad quad;
	quad.vertices[0] = v1 + (v2 - v1) * delta;
	quad.vertices[1] = v1 + (v3 - v1) * delta;
	quad.vertices[2] = v1 + (v4 - v1) * delta;
	quad.vertices[3] = v1 + (v5 - v1) * delta;

	return quad;
};


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



	Quad quad_top = get_quad(top_vertex, back_right_vertex, back_left_vertex, front_left_vertex, front_right_vertex, red);
	Quad quad_bot = get_quad(bot_vertex, front_right_vertex, front_left_vertex, back_left_vertex, back_right_vertex, red);

	Quad quad_front_right = get_quad(front_right_vertex, back_right_vertex, top_vertex, front_left_vertex, bot_vertex, red);
	Quad quad_front_left = get_quad(front_left_vertex, front_right_vertex, top_vertex, back_left_vertex, bot_vertex, red);

	Quad quad_back_right = get_quad(back_right_vertex, back_left_vertex, top_vertex, front_right_vertex, bot_vertex, red);
	Quad quad_back_left = get_quad(back_left_vertex, front_left_vertex, top_vertex, back_right_vertex, bot_vertex, red);
	


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


	emit_quad(hex_bot_front.vertices[2], hex_top_front.vertices[3], hex_bot_front.vertices[3], hex_top_front.vertices[2]);
	emit_quad(hex_top_front.vertices[5], hex_top_front.vertices[4], hex_top_right.vertices[0], hex_top_right.vertices[1]);
	emit_quad(hex_top_left.vertices[5], hex_top_left.vertices[4], hex_top_front.vertices[0], hex_top_front.vertices[1]);
	emit_quad(hex_top_right.vertices[5], hex_top_right.vertices[4], hex_top_back.vertices[0], hex_top_back.vertices[1]);

	emit_quad(hex_top_left.vertices[1], hex_top_left.vertices[0], hex_top_back.vertices[4], hex_top_back.vertices[5]);

	emit_octagon(hex_top_front.vertices[0], hex_top_front.vertices[5], hex_top_right.vertices[0], hex_top_right.vertices[5],
				 hex_top_back.vertices[0], hex_top_back.vertices[5], hex_top_left.vertices[0], hex_top_left.vertices[5]);

	emit_octagon(hex_top_front.vertices[0], hex_top_front.vertices[5], hex_top_right.vertices[0], hex_top_right.vertices[5],
		hex_top_back.vertices[0], hex_top_back.vertices[5], hex_top_left.vertices[0], hex_top_left.vertices[5]);


	// Emit hexagon faces.
	emit_hexagon(hex_top_front, blue);
	emit_hexagon(hex_top_right, blue);
	emit_hexagon(hex_top_back, blue);
	emit_hexagon(hex_top_left, blue);
	
	emit_hexagon(hex_bot_front, blue);
	emit_hexagon(hex_bot_right, blue);
	emit_hexagon(hex_bot_back, blue);
	emit_hexagon(hex_bot_left, blue);
	
}