#version 330 core

layout(points) in;
layout(line_strip, max_vertices = 16) out;


uniform mat4 projection;
uniform mat4 view;

uniform float random_values[8];

void emit_vertex(vec2 vertex)
{
	gl_Position = projection * view * vec4(vertex, 0, 1.0);
	EmitVertex();
}

void emit_line(vec2 p1, vec2 p2)
{
	emit_vertex(p1);
	emit_vertex(p2);

	EndPrimitive();
}


void main()
{
	vec2 center = gl_in[0].gl_Position.xy;

	// -- VERTICES -------------------------------------------------------------------------
	vec2 vertices[8];
	vertices[0] = vec2(center.x - 2, center.y + 2);
	vertices[1] = vec2(center.x, center.y + 2);
	vertices[2] = vec2(center.x + 2, center.y + 2);
	vertices[3] = vec2(center.x + 3, center.y);
	vertices[4] = vec2(center.x + 2, center.y - 2);
	vertices[5] = vec2(center.x, center.y - 2);
	vertices[6] = vec2(center.x - 2, center.y - 2);
	vertices[7] = vec2(center.x - 3, center.y);

	// -- MID POINTS -------------------------------------------------------------------------
	vec2 midpoints[8];
	for (int i = 0; i < 8; i++)
	{
		// Randomize position.
		vertices[i].x += random_values[i];

		// Compute midpoint.
		midpoints[i] = (center + vertices[i]) / 2;
	}

	// -- LINES -------------------------------------------------------------------------
	float slopes[8];
	float intercepts[8];

	for (int i = 0; i < 8; i++)
	{
		// Perpendicular vector.
		vec2 director = vertices[i] - center;
		director = vec2(director.y, -1 * director.x);

		// Singularity handling.
		if (director.x == 0) {
			director.x = 0.00001;
		}

		// Compute slopes and intercepts.
		slopes[i] = director.y / director.x;
		intercepts[i] = midpoints[i].y - slopes[i] * midpoints[i].x;
	}

	// -- INTERSECTIONS -------------------------------------------------------------------------
	// y1 = ax + c; y2 = bx + d
	// x = (d - c) / (a - b)
	vec2 intersections[8];
	for (int i = 0; i < 8; i++)
	{
		intersections[i].x = (intercepts[int(mod(i + 1, 8))] - intercepts[i]) / (slopes[i] - slopes[int(mod(i + 1, 8))]);
		intersections[i].y = slopes[i] * intersections[i].x + intercepts[i];
	}

	for (int i = 0; i < 8; i++)
	{
		emit_line(intersections[i], intersections[int(mod(i + 1, 8))]);
	}
}