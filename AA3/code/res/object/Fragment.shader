#version 330

in vec4 gNormal;
in vec4 gUvs;
in vec4 fragPos
out vec4 out_Color;

uniform mat4 view;
uniform mat4 model;
uniform vec3 objectColor;
uniform vec3 lightColor[];
uniform vec4 lightPos[];

uniform float ambientStrength[];
uniform float specularStrength[];
uniform float specularPower[];
uniform float diffStrength[];
uniform int lightCount;

uniform int useToon, useStencil;

void main()
{
	vec3 ambient(); 
	for (int i = 0; i < lightCount; i++) 
	{
		ambient += ambientStrength[i] * lightColor[i];
	}

	vec4 norm = normalize(gNormal);
	vec4 lightDir[lightCount];	
	float diff[lightCount];
	vec3 diffuse();

	for (int = 0; i < lightCount; i++)
	{
		lightDir[i] = normalize(lightPos[i] - fragPos);
		diff[i] = max(dot(norm, lightDir[i]), 0.0);

		if (useToon == 1) 
		{
			if (diff[i] < 0.2f) diff[i] = 0.f;
			else if (diff[i] < 0.4f) diff[i] = 0.2f;
			else if (diff[i] < 0.5f) diff[i] = 0.4f;
			else diff[i] = 1.f;
		}
	
		diffuse += diffStrength[i] * diff[i] * lightColor[i];
	}
	
	vec4 viewDir = normalize(-fragPos);
	vec4 reflectDir[]; 
	float spec[];
	vec3 specular();

	for (int = 0; i < lightCount; i++)
	{
		reflectDir[i] = reflect(-lightDir[i], norm);
		spec[i] = pow(max(dot(viewDir, reflectDir[i]), 0.0), specularPower[i]);
		
		if (useToon == 1)
		{
			if (spec[i] < 0.2f) spec[i] = 0.f;
			else if (spec[i] < 0.4f) spec[i] = 0.2f;
			else if (spec[i] < 0.5f) spec[i] = 0.4f;
			else spec[i] = 1.f;
		}

		specular += specularStrength[i] * spec[i] * lightColor[i];
	}
	
	vec3 result = ambient + diffuse + specular;
	out_Color = vec4(result * objectColor, 1.0);
}