#version 330 core

out vec4 out_Color;
in vec4 face_color;

void main()
{
	out_Color = face_color;
}