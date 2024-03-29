#version 330

in vec4 gNormal;
in vec4 gUvs;
in vec4 gFragPos;
out vec4 out_Color;

uniform mat4 view;
uniform mat4 model;
uniform vec3 objectColor;
uniform vec3 lightColor[2];
uniform vec4 lightPos[2];

uniform float ambientStrength[2];
uniform float specularStrength[2];
uniform float specularPower[2];
uniform float diffStrength[2];

uniform int lightCount;

uniform int useToon, useStencil;

void main()
{
	vec3 ambient = vec3(0.0, 0.0, 0.0);
	for (int i = 0; i < lightCount; i++) 
	{
		ambient += ambientStrength[i] * lightColor[i];
	}

	vec4 norm = normalize(gNormal);		
	vec3 diffuse = vec3(0.0, 0.0, 0.0);

	for (int i = 0; i < lightCount; i++)
	{
		float diff;

		vec4 lightDir = normalize(view * lightPos[i] - gFragPos);
		diff = max(dot(norm, lightDir), 0.0);

		if (useToon == 1) 
		{
			if (diff < 0.2f) diff = 0.f;
			else if (diff < 0.4f) diff = 0.2f;
			else if (diff < 0.5f) diff = 0.4f;
			else diff = 1.f;
		}
	
		diffuse += diffStrength[i] * diff * lightColor[i];
	}
	
	vec4 viewDir = normalize(-gFragPos);
	vec3 specular = vec3(0.0, 0.0, 0.0);

	for (int i = 0; i < lightCount; i++)
	{
		vec4 lightDir = normalize(view * lightPos[i] - gFragPos);
		vec4 reflectDir = reflect(-lightDir, norm);

		float spec = pow(max(dot(viewDir, reflectDir), 0.0), specularPower[i]);
		
		if (useToon == 1)
		{
			if (spec < 0.2f) spec = 0.f;
			else if (spec < 0.4f) spec = 0.2f;
			else if (spec < 0.5f) spec = 0.4f;
			else spec = 1.f;
		}

		specular += specularStrength[i] * spec * lightColor[i];
	}
	

	vec3 result = ambient + diffuse + specular;
	out_Color = vec4(result * objectColor, 1.0);
}