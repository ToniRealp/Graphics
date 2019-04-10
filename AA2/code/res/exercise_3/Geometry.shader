#version 330 core

layout(points) in;
layout(points, max_vertices = 16) out;


uniform mat4 projection;
uniform mat4 view;



void main()
{
	vec2 center = gl_in[0].gl_Position.xy;

	vec2 vertices[8];
	vertices[0] = vec2(center.x - 2, center.y + 2);
	vertices[1] = vec2(center.x, center.y + 2);
	vertices[2] = vec2(center.x + 2, center.y + 2);
	vertices[3] = vec2(center.x + 3, center.y);
	vertices[4] = vec2(center.x + 2, center.y - 2);
	vertices[5] = vec2(center.x, center.y - 2);
	vertices[6] = vec2(center.x - 2, center.y - 2);
	vertices[7] = vec2(center.x - 3, center.y);

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
		director = vec2(director.y, -1 * director.x);

		// Compute slopes and intercepts.
		if (director.x == 0) {
			director.x = 0.00001;
		}
		slopes[i] = director.y / director.x;
		intercepts[i] = midpoints[i].y - slopes[i] * midpoints[i].x;


		/*float y1 = slopes[i] * 100 + intercepts[i];
		gl_Position = projection * view * vec4(100, y1, 0, 1.0);
		EmitVertex();

		float y2 = slopes[i] * -100 + intercepts[i];
		gl_Position = projection * view * vec4(-100, y2, 0, 1.0);
		EmitVertex();

		EndPrimitive();*/
	}

	// Intersections
	// y1 = ax + c; y2 = bx + d
	// x = (d - c) / (a - b)
	for (int i = 0; i < 8; i++)
	{

		float x = (intercepts[int(mod(i + 1,8))] - intercepts[i]) / (slopes[i] - slopes[int(mod(i + 1,8))]);
		float y = slopes[i] * x + intercepts[i];

		gl_Position = projection * view * vec4(x, y, 0, 1.0);
		EmitVertex();

		EndPrimitive();
	}
}