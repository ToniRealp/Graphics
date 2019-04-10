#version 330 core

out vec4 out_Color; 
in vec3 face_color;

void main()
{
	out_Color = vec4(face_color, 1.0f);
}