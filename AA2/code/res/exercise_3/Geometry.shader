#version 330 core

layout(lines) in;
layout(line_strip, max_vertices = 128) out;


uniform mat4 projection;
uniform mat4 view;



void main()
{
	vec2 center = gl_in[0].gl_Position.xy;

	vec2 vertices[8];

	int i = 0;
	for (int x = -1; x < 2; ++x)
	{
		for (int y = -1; y < 2; ++y)
		{
			if (x == 0 && y == 0) continue;

			vertices[i] = vec2(center.x + x * 2, center.y + y * 2);
			i++;
		}
	}

	// Midpoints
	vec2 midpoints[8];
	for (int i = 0; i < 8; i++)
	{
		midpoints[i] = (center + vertices[i]) / 2;
	}

	// Lines
	float slopes[8];
	float intercepts[8];

	for (int i = 0; i < 8; i++)
	{
		// Perpendicular vector.
		vec2 director = vertices[i] - center;
		director = vec2(-1 * director.y, director.x);

		// Compute slopes and intercepts.
		slopes[i] = director.y / director.x;
		intercepts[i] = midpoints[i].y - slopes[i] * midpoints[i].x;


		float y1 = slopes[i] * 100 + intercepts[i];
		gl_Position = projection * view * vec4(100, y1, 0, 1.0);
		EmitVertex();

		float y2 = slopes[i] * -100 + intercepts[i];
		gl_Position = projection * view * vec4(-100, y2, 0, 1.0);
		EmitVertex();
		EndPrimitive();
	}

	// Intersections
	// y = ax + c
	// y = bx + d
	// x = (d - c) / (a - b)
	for (int i = 0; i < 8; i++)
	{
		float x = (intercepts[(i + 1) % 8] - intercepts[i]) / (slopes[i] - slopes[(i + 1) % 8]);
		float y = slopes[i] * x + intercepts[i];
	}
}