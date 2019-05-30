#version 330

in vec4 gNormal;
in vec4 gUvs;
in vec4 gFragPos;
out vec4 out_Color;

uniform mat4 view;
uniform mat4 model;
uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec4 lightPos;

uniform float ambientStrength;
uniform float specularStrength;
uniform float specularPower;
uniform float diffStrength;

uniform int lightCount;

uniform int useToon, useStencil;

void main()
{
	vec3 ambient = vec3(0.0, 0.0, 0.0);
	for (int i = 0; i < lightCount; i++) 
	{
		ambient += ambientStrength * lightColor;
	}

	vec4 norm = normalize(gNormal);		
	vec3 diffuse = vec3(0.0, 0.0, 0.0);

	for (int i = 0; i < lightCount; i++)
	{
		float diff;

		vec4 lightDir = normalize(view * lightPos - gFragPos);
		diff = max(dot(norm, lightDir), 0.0);

		if (useToon == 1) 
		{
			if (diff < 0.2f) diff = 0.f;
			else if (diff < 0.4f) diff = 0.2f;
			else if (diff < 0.5f) diff = 0.4f;
			else diff = 1.f;
		}
	
		diffuse += diffStrength * diff * lightColor;
	}
	
	vec4 viewDir = normalize(-gFragPos);
	vec3 specular = vec3(0.0, 0.0, 0.0);

	for (int i = 0; i < lightCount; i++)
	{
		vec4 lightDir = normalize(view * lightPos - gFragPos);
		vec4 reflectDir = reflect(-lightDir, norm);

		float spec = pow(max(dot(viewDir, reflectDir), 0.0), specularPower);
		
		if (useToon == 1)
		{
			if (spec < 0.2f) spec = 0.f;
			else if (spec < 0.4f) spec = 0.2f;
			else if (spec < 0.5f) spec = 0.4f;
			else spec = 1.f;
		}

		specular += specularStrength * spec * lightColor;
	}
	

	vec3 result = ambient + diffuse + specular;
	out_Color = vec4(result * objectColor, 1.0);
}