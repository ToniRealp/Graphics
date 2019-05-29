#version 330

in vec4 vert_Normal;
in vec4 fragPos;
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

void main()
{
	vec3 ambient = ambientStrength * lightColor;

	vec4 norm = normalize(vert_Normal);
	vec4 lightDir = normalize(lightPos - fragPos);

	float diff = max(dot(norm, lightDir), 0.0);
	bool diffChanged = false;
	for (int i = 0; i < 4; i++)
	{
		if (!diffChanged)
		{
			if (diff <= i / 4)
			{
				diff = i / 4;
				diffChanged = true;
			}
		}
	}

	if (diff < 0.2f) diff = 0.f;
	else if (diff < 0.4f) diff = 0.2f;
	else if (diff < 0.5f) diff = 0.4f;
	else diff = 1.f;

	vec3 diffuse = diffStrength * diff * lightColor;
	vec4 viewDir = normalize(-fragPos);
	vec4 reflectDir = reflect(-lightDir, norm);

	float spec = pow(max(dot(viewDir, reflectDir), 0.0), specularPower);

	if (spec < 0.2f) spec = 0.f;
	else if (spec < 0.4f) spec = 0.2f;
	else if (spec < 0.5f) spec = 0.4f;
	else spec = 1.f;

	vec3 specular = specularStrength * spec * lightColor;

	vec3 result = ambient + diffuse + specular;
	out_Color = vec4(result * objectColor, 1.0);
}