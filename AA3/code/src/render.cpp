#include <GL\glew.h>
#include <glm\gtc\type_ptr.hpp>
#include <glm\gtc\matrix_transform.hpp>
#include <glm/gtc/noise.hpp>
#include <cstdio>
#include <cassert>

#include <imgui\imgui.h>
#include <imgui\imgui_impl_sdl_gl3.h>

#include "GL_framework.h"
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>
#include <algorithm>
#include <array>
#include <vector>
#include <unordered_map>
#include <functional>


namespace ImGui {
	void Render();
}
namespace Axis {
void setupAxis();
void cleanupAxis();
void drawAxis();
}

namespace RenderVars {
	const float FOV = glm::radians(65.f);
	const float zNear = 0.1f;
	const float zFar = 50.f;

	glm::mat4 _projection;
	glm::mat4 _modelView;
	glm::mat4 _MVP;
	glm::mat4 _inv_modelview;
	glm::vec4 _cameraPoint;

	struct prevMouse {
		float lastx, lasty;
		MouseEvent::Button button = MouseEvent::Button::None;
		bool waspressed = false;
	} prevMouse;

	glm::vec3 cameraPosition;
	glm::vec2 cameraRotation;

	float panv[3] = { 0.f, 0.f, 0.f };
	float rota[2] = { 0.f, 0.f };
}
namespace RV = RenderVars;

void GLResize(int width, int height) {
	glViewport(0, 0, width, height);
	if(height != 0) RV::_projection = glm::perspective(RV::FOV, (float)width / (float)height, RV::zNear, RV::zFar);
	else RV::_projection = glm::perspective(RV::FOV, 0.f, RV::zNear, RV::zFar);
}

void GLmousecb(MouseEvent ev) {
	if(RV::prevMouse.waspressed && RV::prevMouse.button == ev.button) {
		float diffx = ev.posx - RV::prevMouse.lastx;
		float diffy = ev.posy - RV::prevMouse.lasty;
		switch(ev.button) {
		case MouseEvent::Button::Left: // ROTATE
			RV::rota[0] += diffx * 0.005f;
			RV::rota[1] += diffy * 0.005f;
			break;
		case MouseEvent::Button::Right: // MOVE XY
			RV::panv[0] += diffx * 0.03f;
			RV::panv[1] -= diffy * 0.03f;
			break;
		case MouseEvent::Button::Middle: // MOVE Z
			RV::panv[2] += diffy * 0.05f;
			break;
		default: break;
		}
	} else {
		RV::prevMouse.button = ev.button;
		RV::prevMouse.waspressed = true;
	}
	RV::prevMouse.lastx = ev.posx;
	RV::prevMouse.lasty = ev.posy;
}

//////////////////////////////////////////////////


GLuint compileShader(const char* shaderStr, GLenum shaderType, const char* name="") {
	GLuint shader = glCreateShader(shaderType);
	glShaderSource(shader, 1, &shaderStr, NULL);
	glCompileShader(shader);

	GLint res;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &res);
	if (res == GL_FALSE) {
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &res);
		char *buff = new char[res];
		glGetShaderInfoLog(shader, res, &res, buff);
		fprintf(stderr, "Error Shader %s: %s", name, buff);
		delete[] buff;
		glDeleteShader(shader);
		return 0;
	}

	return shader;
}

GLuint compileShader(GLenum shaderType, const std::string& path, const std::string& name = "")
{
	std::ifstream file(path);
	if (!file.is_open()) std::cout << "Shader not found in " << path << std::endl;

	std::stringstream buffer;

	buffer << file.rdbuf();

	return compileShader(buffer.str().c_str(), shaderType, name.c_str());
}

void linkProgram(GLuint program) {
	glLinkProgram(program);
	GLint res;
	glGetProgramiv(program, GL_LINK_STATUS, &res);
	if (res == GL_FALSE) {
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &res);
		char *buff = new char[res];
		glGetProgramInfoLog(program, res, &res, buff);
		fprintf(stderr, "Error Link: %s", buff);
		delete[] buff;
	}
}


namespace Axis {
GLuint AxisVao;
GLuint AxisVbo[3];
GLuint AxisShader[2];
GLuint AxisProgram;

float AxisVerts[] = {
	0.0, 0.0, 0.0,
	1.0, 0.0, 0.0,
	0.0, 0.0, 0.0,
	0.0, 1.0, 0.0,
	0.0, 0.0, 0.0,
	0.0, 0.0, 1.0
};
float AxisColors[] = {
	1.0, 0.0, 0.0, 1.0,
	1.0, 0.0, 0.0, 1.0,
	0.0, 1.0, 0.0, 1.0,
	0.0, 1.0, 0.0, 1.0,
	0.0, 0.0, 1.0, 1.0,
	0.0, 0.0, 1.0, 1.0
};
GLubyte AxisIdx[] = {
	0, 1,
	2, 3,
	4, 5
};
const char* Axis_vertShader =
"#version 330\n\
in vec3 in_Position;\n\
in vec4 in_Color;\n\
out vec4 vert_color;\n\
uniform mat4 mvpMat;\n\
void main() {\n\
	vert_color = in_Color;\n\
	gl_Position = mvpMat * vec4(in_Position, 1.0);\n\
}";
const char* Axis_fragShader =
"#version 330\n\
in vec4 vert_color;\n\
out vec4 out_Color;\n\
void main() {\n\
	out_Color = vert_color;\n\
}";

void setupAxis() {
	glGenVertexArrays(1, &AxisVao);
	glBindVertexArray(AxisVao);
	glGenBuffers(3, AxisVbo);

	glBindBuffer(GL_ARRAY_BUFFER, AxisVbo[0]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 24, AxisVerts, GL_STATIC_DRAW);
	glVertexAttribPointer((GLuint)0, 3, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(0);

	glBindBuffer(GL_ARRAY_BUFFER, AxisVbo[1]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 24, AxisColors, GL_STATIC_DRAW);
	glVertexAttribPointer((GLuint)1, 4, GL_FLOAT, false, 0, 0);
	glEnableVertexAttribArray(1);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, AxisVbo[2]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLubyte) * 6, AxisIdx, GL_STATIC_DRAW);

	glBindVertexArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

	AxisShader[0] = compileShader(Axis_vertShader, GL_VERTEX_SHADER, "AxisVert");
	AxisShader[1] = compileShader(Axis_fragShader, GL_FRAGMENT_SHADER, "AxisFrag");

	AxisProgram = glCreateProgram();
	glAttachShader(AxisProgram, AxisShader[0]);
	glAttachShader(AxisProgram, AxisShader[1]);
	glBindAttribLocation(AxisProgram, 0, "in_Position");
	glBindAttribLocation(AxisProgram, 1, "in_Color");
	linkProgram(AxisProgram);
}
void cleanupAxis() {
	glDeleteBuffers(3, AxisVbo);
	glDeleteVertexArrays(1, &AxisVao);

	glDeleteProgram(AxisProgram);
	glDeleteShader(AxisShader[0]);
	glDeleteShader(AxisShader[1]);
}
void drawAxis() {
	glBindVertexArray(AxisVao);
	glUseProgram(AxisProgram);
	glUniformMatrix4fv(glGetUniformLocation(AxisProgram, "mvpMat"), 1, GL_FALSE, glm::value_ptr(RV::_MVP));
	glDrawElements(GL_LINES, 6, GL_UNSIGNED_BYTE, 0);

	glUseProgram(0);
	glBindVertexArray(0);
}
}

namespace Cube {
GLuint cubeVao;
GLuint cubeVbo[3];
GLuint cubeShaders[3];
GLuint cubeProgram;
glm::mat4 objMat = glm::mat4(1.f);

extern const float halfW = 0.5f;
int numVerts = 24 + 6; // 4 vertex/face * 6 faces + 6 PRIMITIVE RESTART

					   //   4---------7
					   //  /|        /|
					   // / |       / |
					   //5---------6  |
					   //|  0------|--3
					   //| /       | /
					   //|/        |/
					   //1---------2
glm::vec3 verts[] = {
	glm::vec3(-halfW, -halfW, -halfW),
	glm::vec3(-halfW, -halfW,  halfW),
	glm::vec3(halfW, -halfW,  halfW),
	glm::vec3(halfW, -halfW, -halfW),
	glm::vec3(-halfW,  halfW, -halfW),
	glm::vec3(-halfW,  halfW,  halfW),
	glm::vec3(halfW,  halfW,  halfW),
	glm::vec3(halfW,  halfW, -halfW)
};
glm::vec3 norms[] = {
	glm::vec3(0.f, -1.f,  0.f),
	glm::vec3(0.f,  1.f,  0.f),
	glm::vec3(-1.f,  0.f,  0.f),
	glm::vec3(1.f,  0.f,  0.f),
	glm::vec3(0.f,  0.f, -1.f),
	glm::vec3(0.f,  0.f,  1.f)
};

glm::vec3 cubeVerts[] = {
	verts[1], verts[0], verts[2], verts[3],
	verts[5], verts[6], verts[4], verts[7],
	verts[1], verts[5], verts[0], verts[4],
	verts[2], verts[3], verts[6], verts[7],
	verts[0], verts[4], verts[3], verts[7],
	verts[1], verts[2], verts[5], verts[6]
};
glm::vec3 cubeNorms[] = {
	norms[0], norms[0], norms[0], norms[0],
	norms[1], norms[1], norms[1], norms[1],
	norms[2], norms[2], norms[2], norms[2],
	norms[3], norms[3], norms[3], norms[3],
	norms[4], norms[4], norms[4], norms[4],
	norms[5], norms[5], norms[5], norms[5]
};
GLubyte cubeIdx[] = {
	0, 1, 2, 3, UCHAR_MAX,
	4, 5, 6, 7, UCHAR_MAX,
	8, 9, 10, 11, UCHAR_MAX,
	12, 13, 14, 15, UCHAR_MAX,
	16, 17, 18, 19, UCHAR_MAX,
	20, 21, 22, 23, UCHAR_MAX
};

void setupCube() {
	glGenVertexArrays(1, &cubeVao);
	glBindVertexArray(cubeVao);
	glGenBuffers(3, cubeVbo);

	glBindBuffer(GL_ARRAY_BUFFER, cubeVbo[0]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVerts), cubeVerts, GL_STATIC_DRAW);
	glVertexAttribPointer((GLuint)0, 3, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(0);

	glBindBuffer(GL_ARRAY_BUFFER, cubeVbo[1]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(cubeNorms), cubeNorms, GL_STATIC_DRAW);
	glVertexAttribPointer((GLuint)1, 3, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(1);

	glPrimitiveRestartIndex(UCHAR_MAX);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cubeVbo[2]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(cubeIdx), cubeIdx, GL_STATIC_DRAW);

	glBindVertexArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

	cubeShaders[0] = compileShader(GL_VERTEX_SHADER, "res/shaders/Vertex.shader", "cubeVert");
	cubeShaders[1] = compileShader(GL_GEOMETRY_SHADER, "res/shaders/Geometry.shader","cubeGeo");
	cubeShaders[2] = compileShader(GL_FRAGMENT_SHADER, "res/shaders/Fragment.shader", "cubeFrag");

	cubeProgram = glCreateProgram();
	glAttachShader(cubeProgram, cubeShaders[0]);
	glAttachShader(cubeProgram, cubeShaders[1]);
	glAttachShader(cubeProgram, cubeShaders[2]);
	glBindAttribLocation(cubeProgram, 0, "in_Position");
	glBindAttribLocation(cubeProgram, 1, "in_Normal");
	linkProgram(cubeProgram);
}
void cleanupCube() {
	glDeleteBuffers(3, cubeVbo);
	glDeleteVertexArrays(1, &cubeVao);

	glDeleteProgram(cubeProgram);
	glDeleteShader(cubeShaders[0]);
	glDeleteShader(cubeShaders[1]);
}
void updateCube(const glm::mat4& transform) {
	objMat = transform;
}
void drawCube()
{
	glEnable(GL_PRIMITIVE_RESTART);
	glBindVertexArray(cubeVao);
	glUseProgram(cubeProgram);
	glUniformMatrix4fv(glGetUniformLocation(cubeProgram, "objMat"), 1, GL_FALSE, glm::value_ptr(objMat));
	glUniformMatrix4fv(glGetUniformLocation(cubeProgram, "mv_Mat"), 1, GL_FALSE, glm::value_ptr(RenderVars::_modelView));
	glUniformMatrix4fv(glGetUniformLocation(cubeProgram, "mvpMat"), 1, GL_FALSE, glm::value_ptr(RenderVars::_MVP));
	glUniform4f(glGetUniformLocation(cubeProgram, "color"), 0.1f, 1.f, 1.f, 0.f);

	static float alpha = 0.0f;
	alpha += 0.05f;

	if (alpha > glm::two_pi<float>()) alpha = 0.0;

	glUniform1f(glGetUniformLocation(cubeProgram, "alpha"), glm::sin(alpha));
	glDrawElements(GL_TRIANGLE_STRIP, numVerts, GL_UNSIGNED_BYTE, 0);

	glUseProgram(0);
	glBindVertexArray(0);
	glDisable(GL_PRIMITIVE_RESTART);
}
}

namespace Config
{
	float radius = 28.5f;
	bool activateBulb = false;
}

namespace Shader
{
	unsigned int CompileShader(unsigned int type, const std::string& source)
	{
		unsigned int id = glCreateShader(type);

		// Provide the shader code and compile.
		const char* src = source.c_str();
		glShaderSource(id, 1, &src, nullptr);
		glCompileShader(id);

		GLint res;
		glGetShaderiv(id, GL_COMPILE_STATUS, &res);
		if (res == GL_FALSE) {
			glGetShaderiv(id, GL_INFO_LOG_LENGTH, &res);
			char *buff = new char[res];
			glGetShaderInfoLog(id, res, &res, buff);

			switch (type)
			{
				case GL_FRAGMENT_SHADER:
					std::cout << "FRAGMENT SHADER" << std::endl;
					break;

				case GL_VERTEX_SHADER:
					std::cout << "VERTEX SHADER" << std::endl;
					break;

				case GL_GEOMETRY_SHADER:
					std::cout << "GEOMETRY SHADER" << std::endl;
					break;

				default:
					std::cout << "NON-HANDLED SHADER" << std::endl;
					break;
			}
			
			fprintf(stderr, "Error Shader %s", buff);
			delete[] buff;
			glDeleteShader(id);
			return 0;
		}

		return id;
	}

	unsigned int CreateProgram(const std::string& vertexShader, const std::string& fragmentShader, const std::string& geometryShader = "")
	{
		unsigned int program = glCreateProgram();

		// Compile and attach the shaders.
		unsigned int vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
		unsigned int fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);
		glAttachShader(program, vs);
		glAttachShader(program, fs);

		if (!geometryShader.empty())
		{
			unsigned int gs = CompileShader(GL_GEOMETRY_SHADER, geometryShader);
			glAttachShader(program, gs);
		}

		glLinkProgram(program);

		GLint res;
		glGetProgramiv(program, GL_LINK_STATUS, &res);
		if (res == GL_FALSE) {
			glGetProgramiv(program, GL_INFO_LOG_LENGTH, &res);
			char *buff = new char[res];
			glGetProgramInfoLog(program, res, &res, buff);
			fprintf(stderr, "Error Link: %s", buff);
			delete[] buff;
		}

		glValidateProgram(program);

		return program;
	}

	// Returns the source code of the shader located at the specified path.
	std::string ParseShader(const std::string& path)
	{
		std::ifstream file(path);

		if (!file.is_open()) std::cout << "Cannot open the shader at path: " + path;

		std::stringstream buffer;

		buffer << file.rdbuf();

		return buffer.str();
	}

	void SetMat4(unsigned int program, const std::string& name, glm::mat4 matrix)
	{
		glUniformMatrix4fv(glGetUniformLocation(program, name.c_str()), 1, GL_FALSE, glm::value_ptr(matrix));
	}

	void SetFloat(unsigned int program, const std::string& name, float value)
	{
		glUniform1f(glGetUniformLocation(program, name.c_str()), value);
	}

	void SetFloatArray(unsigned int program, const std::string& name, size_t count, float* values)
	{
		glUniform1fv(glGetUniformLocation(program, name.c_str()), count, values);
	}

	void SetVec3(unsigned int program, const std::string& name, glm::vec3 value)
	{
		glUniform3f(glGetUniformLocation(program, name.c_str()), value.x, value.y, value.z);
	}

	void SetVec3Array(unsigned int program, const std::string& name, size_t count, float* values)
	{
		glUniform3fv(glGetUniformLocation(program, name.c_str()), count, values);
	}

	void SetVec4Array(unsigned int program, const std::string& name, size_t count, float* values)
	{
		glUniform4fv(glGetUniformLocation(program, name.c_str()), count, values);
	}

	void SetBool(unsigned int program, const std::string& name, bool value)
	{
		glUniform1i(glGetUniformLocation(program, name.c_str()), value);
	}

	void SetInt(unsigned int program, const std::string& name, int value)
	{
		glUniform1i(glGetUniformLocation(program, name.c_str()), value);
	}
}

namespace Light
{
	float kAmbient[2], kDiffuse[2], kSpecular[2], specularPower[2];
	glm::vec4 positions[2];
	glm::vec3 colors[2];

	int counts = 2;

	void Init()
	{
		for (int i = 0; i < counts; ++i)
		{
			positions[i] = { 0.0, 0.0, 0.0, 1.0 };
			colors[i] = { 1.0, 1.0, 1.0 };
			kAmbient[i] = 0.5f;
			kDiffuse[i] = 0.5f;
			kSpecular[i] = 0.5f;
			specularPower[i] = 2.f;
		}
		
	}

	void SetColor(int index, glm::vec3 color)
	{
		colors[index] = color;
	}

	void SetPosition(int index, glm::vec3 position)
	{
		positions[index] = glm::vec4(position, 1.f);
	}

	void SetCounts(int number)
	{
		counts = number;
	}
};

class Object
{
private:
	unsigned int vao{}, vbo[3]{};
	unsigned int program{};

	static const glm::mat4& view;
	static const glm::mat4& projection;

	glm::mat4 model = glm::mat4(1.f);

	std::vector<glm::vec3> vertices;
	std::vector<glm::vec2> uvs;
	std::vector<glm::vec3> normals;

	bool Load(const char * path, std::vector<glm::vec3>& out_vertices, std::vector<glm::vec2>& out_uvs, std::vector<glm::vec3>& out_normals)
	{
		std::vector<unsigned int> vertexIndices, uvIndices, normalIndices;
		std::vector<glm::vec3> temp_vertices;
		std::vector<glm::vec2> temp_uvs;
		std::vector<glm::vec3> temp_normals;

		FILE * file = fopen(path, "r");
		if (file == NULL) {
			printf("Impossible to open the file !\n");
			return false;
		}

		while (true)
		{
			char lineHeader[128];
			// read the first word of the line
			int res = fscanf(file, "%s", lineHeader);
			if (res == EOF)
				break; // EOF = End Of File. Quit the loop.

			if (strcmp(lineHeader, "v") == 0) {
				glm::vec3 vertex;
				fscanf(file, "%f %f %f\n", &vertex.x, &vertex.y, &vertex.z);
				temp_vertices.push_back(vertex);

			}
			else if (strcmp(lineHeader, "vt") == 0) {
				glm::vec2 uv;
				fscanf(file, "%f %f\n", &uv.x, &uv.y);
				temp_uvs.push_back(uv);
			}
			else if (strcmp(lineHeader, "vn") == 0) {
				glm::vec3 normal;
				fscanf(file, "%f %f %f\n", &normal.x, &normal.y, &normal.z);
				temp_normals.push_back(normal);
			}
			else if (strcmp(lineHeader, "f") == 0) {
				std::string vertex1, vertex2, vertex3;
				unsigned int vertexIndex[3], uvIndex[3], normalIndex[3];
				int matches = fscanf(file, "%d/%d/%d %d/%d/%d %d/%d/%d\n", &vertexIndex[0], &uvIndex[0], &normalIndex[0], &vertexIndex[1], &uvIndex[1], &normalIndex[1], &vertexIndex[2], &uvIndex[2], &normalIndex[2]);
				if (matches != 9) {
					printf("File can't be read by our simple parser : ( Try exporting with other options\n");
					return false;
				}
				vertexIndices.push_back(vertexIndex[0]);
				vertexIndices.push_back(vertexIndex[1]);
				vertexIndices.push_back(vertexIndex[2]);
				uvIndices.push_back(uvIndex[0]);
				uvIndices.push_back(uvIndex[1]);
				uvIndices.push_back(uvIndex[2]);
				normalIndices.push_back(normalIndex[0]);
				normalIndices.push_back(normalIndex[1]);
				normalIndices.push_back(normalIndex[2]);
			}
		}

		for (unsigned int i = 0; i < vertexIndices.size(); i++) {
			unsigned int vertexIndex = vertexIndices[i];
			glm::vec3 vertex = temp_vertices[vertexIndex - 1];
			out_vertices.push_back(vertex);
		}

		for (unsigned int i = 0; i < uvIndices.size(); i++) {
			unsigned int uvIndex = uvIndices[i];
			glm::vec2 uv = temp_uvs[uvIndex - 1];
			out_uvs.push_back(uv);
		}

		for (unsigned int i = 0; i < normalIndices.size(); i++) {
			unsigned int normalIndex = normalIndices[i];
			glm::vec3 normal = temp_normals[normalIndex - 1];
			out_normals.push_back(normal);
		}

		return true;
	}


public:

	bool active;
	glm::vec3 objectColor;

	bool useToon = true, useStencil = true;

	Object() = default;

	Object(const char * path, glm::vec3 color = {1,1,1})
	{
		if (!Load(path, vertices, uvs, normals))
		{
			std::cout << "Could not load model at path: " << path << std::endl;
		}

		objectColor = color;

		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);

		glGenBuffers(3, vbo);

		glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(glm::vec3) * vertices.size(), vertices.data(), GL_STATIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(0);

		glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(glm::vec3) * normals.size(), normals.data(), GL_STATIC_DRAW);
		glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(1);

		glBindBuffer(GL_ARRAY_BUFFER, vbo[2]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(glm::vec2) * uvs.size(), uvs.data(), GL_STATIC_DRAW);
		glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(2);

		const auto vertex_shader = Shader::ParseShader("res/object/Vertex.shader");
		const auto fragment_shader = Shader::ParseShader("res/object/Fragment.shader");
		const auto geometry_shader = Shader::ParseShader("res/object/Geometry.shader");
		
		program = Shader::CreateProgram(vertex_shader, fragment_shader, geometry_shader);
	}

	void UpdateShader(std::string vertexPath, std::string fragmentPath, std::string geometryPath)
	{
		const auto vertex_shader = Shader::ParseShader(vertexPath);
		const auto fragment_shader = Shader::ParseShader(fragmentPath);

		if (!geometryPath.empty())
		{
			const auto geometry_shader = Shader::ParseShader(geometryPath);
			program = Shader::CreateProgram(vertex_shader, fragment_shader, geometry_shader);

			return;
		}

		program = Shader::CreateProgram(vertex_shader, fragment_shader);
	}

	void Clean()
	{
		glDeleteBuffers(2, vbo);
		glDeleteVertexArrays(1, &vao);

		glDeleteProgram(program);
	}

	void Render()
	{
		if (!active) return;
		glEnable(GL_STENCIL_TEST);

		glBindVertexArray(vao);
		glUseProgram(program);

		Shader::SetMat4(program, "model", model);
		Shader::SetMat4(program, "projection", projection);
		Shader::SetMat4(program, "view", view);
		Shader::SetMat4(program, "mvp", projection * view * model);

		Shader::SetVec3(program, "objectColor", objectColor);
		Shader::SetVec3Array(program, "lightColor", 6, &Light::colors[0].x);
		Shader::SetVec4Array(program, "lightPos", 6, &Light::positions[0].x);

		Shader::SetFloatArray(program, "ambientStrength", 6, Light::kAmbient);
		Shader::SetFloatArray(program, "specularStrength", 6, Light::kSpecular);
		Shader::SetFloatArray(program, "specularPower", 6, Light::specularPower);
		Shader::SetFloatArray(program, "diffStrength", 6, Light::kDiffuse);

		Shader::SetBool(program, "useToon", useToon);
		Shader::SetBool(program, "useStencil", 0);
		Shader::SetInt(program, "lightCount", Light::counts);

		glStencilFunc(GL_ALWAYS, 1, 0xFF);
		glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);
		glStencilMask(0xFF);
		glClear(GL_STENCIL_BUFFER_BIT);

		glDrawArrays(GL_TRIANGLES, 0, vertices.size());

		glStencilFunc(GL_NOTEQUAL, 1, 0xFF);
		glStencilMask(0x00);
		glDepthMask(GL_FALSE);

		Shader::SetVec3(program, "objectColor", { 0.f, 0.2f, 0.5f });
		Shader::SetBool(program, "useStencil", useStencil);
		glDrawArrays(GL_TRIANGLES, 0, vertices.size());
		glDepthMask(GL_TRUE);

		glDisable(GL_STENCIL_TEST);
	}

	Object& Scale(float scaleFactor)
	{
		model = scale(model, glm::vec3(scaleFactor));
		return *this;
	}

	Object& Translate(glm::vec3 position)
	{
		Translate(position, model);
		return *this;
	}

	Object& Translate(glm::vec3 position, glm::mat4 matrix)
	{
		model = translate(matrix, position);
		return *this;
	}

	Object& Rotate(float angle, glm::vec3 rotationAxis)
	{
		model = rotate(model, angle, rotationAxis);
		return *this;
	}

	glm::vec3 GetPosition()
	{
		return glm::vec3(model[3]);
	}
};

const glm::mat4& Object::view = RV::_modelView;
const glm::mat4& Object::projection = RV::_projection;

float accum = 0.f, counter = 0.f;


namespace Objects
{
	std::vector<Object> cabins;
	std::unordered_map<std::string, Object> objects;

	bool counterShot = true;	
	float frequency = 1 / (glm::two_pi<float>() / 0.1f);

	// Loads every model with basic shaders.
	void Init()
	{
		objects["chicken"] = { "res/Gallina.obj" };
		objects["support"] = { "res/Patas.obj" };
		objects["trump"] = { "res/Trump.obj"  };
		objects["wheel"] = { "res/Rueda.obj" };

		cabins.resize(20, { "res/Cabina.obj" });
	}

	void Clean()
	{
		for (auto& object : objects)
		{
			object.second.Clean();
		}

		for (auto& cabin : cabins)
		{
			cabin.Clean();
		}

		objects.clear();
	}

	#pragma region RENDER FUNCTIONS

	void Render()
	{
		for (auto& cabin : cabins)
		{
			cabin.Render();
		}

		for (auto& object : objects)
		{
			object.second.Render();
		}
	}

	void Render(std::vector<std::string> keys)
	{
		for (auto& key : keys)
		{
			objects[key].Render();
		}
	}

	#pragma endregion	

	#pragma region HELPER FUNCTIONS
	void Translate(std::string key, glm::vec3 position)
	{
		objects[key].Translate(position);
	}

	void Translate(std::string key, glm::vec3 position, glm::mat4 matrix)
	{
		objects[key].Translate(position, matrix);
	}

	void Rotate(std::string key, float angle, glm::vec3 rotationAxis)
	{
		objects[key].Rotate(angle, rotationAxis);
	}

	void UpdateShader(std::string key, std::string vertexPath, std::string fragmentPath, std::string geometryPath)
	{
		objects[key].UpdateShader(vertexPath, fragmentPath, geometryPath);
	}

	void UpdateShaders(std::string vertexPath, std::string fragmentPath, std::string geometryPath)
	{
		for (auto& object : objects)
		{
			object.second.UpdateShader(vertexPath, fragmentPath, geometryPath);
		}

		for (auto& cabin : cabins)
		{
			cabin.UpdateShader(vertexPath, fragmentPath, geometryPath);
		}
	}

	glm::vec3 GetPosition(std::string key)
	{
		return objects[key].GetPosition();
	}

	void SetColor(std::string key, glm::vec3 color)
	{
		objects[key].objectColor = color;
	}

	void SetCabinsColor(glm::vec3 color)
	{
		for (auto& cabin : cabins)
		{
			cabin.objectColor = color;
		}
	}
	#pragma endregion 

	void SpinCabins()
	{
		for (int i = 0; i < cabins.size(); ++i)
		{
			float alpha = glm::two_pi<float>() * frequency * accum + glm::two_pi<float>()  * i / cabins.size();
			glm::vec3 cabinPosition = { Config::radius * cos(alpha), Config::radius * sin(alpha), 0 };

			cabins[i].Translate(cabinPosition, glm::mat4(1.0f));
		}
	}

	void SpinPassengers()
	{
		float alpha = glm::two_pi<float>() * frequency * accum;
		glm::vec3 position = { Config::radius * cos(alpha), Config::radius * sin(alpha), 0 };

		objects["chicken"].Translate(position, glm::mat4(1.0f)).Translate({ 1.f, -4,0 }).Rotate(-1.57f, { 0.f, 1.f, 0.f });
		objects["trump"].Translate(position, glm::mat4(1.0f)).Translate({ -1.f, -4,0 }).Rotate(1.57f, { 0.f, 1.f, 0.f });
	}

	void MoveBulb(float dt)
	{
		float alpha = glm::two_pi<float>() * frequency * accum;
		glm::vec3 position = { Config::radius * cos(alpha), Config::radius * sin(alpha), 0 };

		Light::SetPosition(1, position);
	}

	void CounterShot()
	{
		if (accum < 2.f) return;

		if (counter < 2.f)
		{
			if (counterShot)
			{
				RV::cameraPosition = -GetPosition("chicken") + glm::vec3(0.40, -2.7, -0.6);
				RV::cameraRotation = { -1.1f, 0.420 };
			}
			else
			{
				RV::cameraPosition = -GetPosition("trump") + glm::vec3(-0.420, -2.160, -0.650);
				RV::cameraRotation = { 1.145, 0.315 };
			}
		}
		else
		{
			counterShot = !counterShot;
			counter = 0.f;
		}
	}
}

namespace Exercise
{
	void Init()
	{
		RV::cameraRotation = { 0.6, 0.150 };
		RV::cameraPosition = { 30, -10, -33 };

		Objects::SetColor("trump", { 1.f, 0.f, 0.f });
		Objects::SetColor("chicken", { 0.f, 0.f, 1.f });
		Objects::SetColor("support", { 1.f, 1.f, 1.f });
		Objects::SetCabinsColor({ 1.f, 1.f, 1.f });

		Light::SetColor(0, { 1.f, 1.f, 1.f });
		Light::SetColor(1, { 0.f, 0.f, 1.f });
	}

	void Run(float dt)
	{
		Objects::Rotate("wheel", 0.1f * dt, { 0.f, 0.f, 1.f });

		Objects::SpinCabins();
		Objects::SpinPassengers();

		Light::SetCounts(1);

		if (Config::activateBulb)
		{
			Objects::MoveBulb(dt);
			Light::SetCounts(2);
		}

		Objects::CounterShot();

		Objects::Render();
	}	
}

namespace Camera
{
	// First moves the camera and then rotates it.
	void Setup(glm::vec3 position, glm::vec2 rotation)
	{
		RV::_modelView = glm::mat4(1.f);
		RV::_modelView = translate(RV::_modelView, position);
		RV::_modelView = rotate(RV::_modelView, rotation.y, glm::vec3(1.f, 0.f, 0.f));
		RV::_modelView = rotate(RV::_modelView, rotation.x, glm::vec3(0.f, 1.f, 0.f));

		RV::_MVP = RV::_projection * RV::_modelView;

		glLineWidth(1.0f);
		Axis::drawAxis();
	}


	// First rotates the camera and the adjusts its position.
	void Setup(glm::vec2 rotation, glm::vec3 position)
	{
		RV::_modelView = glm::mat4(1.f);
		RV::_modelView = rotate(RV::_modelView, rotation.y, glm::vec3(1.f, 0.f, 0.f));
		RV::_modelView = rotate(RV::_modelView, rotation.x, glm::vec3(0.f, 1.f, 0.f));
		RV::_modelView = translate(RV::_modelView, position);

		RV::_MVP = RV::_projection * RV::_modelView;

		glLineWidth(1.0f);
		Axis::drawAxis();
	}
}

void GLinit(int width, int height)
{
	glViewport(0, 0, width, height);
	glClearColor(0.2f, 0.2f, 0.2f, 1.f);
	glClearDepth(1.f);
	glDepthFunc(GL_LEQUAL);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_CULL_FACE);

	RV::_projection = glm::perspective(RV::FOV, (float)width / (float)height, RV::zNear, RV::zFar);
	Axis::setupAxis();

	Light::Init();
	Objects::Init();
	Exercise::Init();
}

void GLrender(float dt)
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	accum += dt;
	counter += dt;

	Camera::Setup(RV::cameraRotation, RV::cameraPosition);
	Exercise::Run(dt);

	ImGui::Render();
}

void GLcleanup()
{
	Axis::cleanupAxis();
	Objects::Clean();
}

void GUI()
{
	bool show = true;
	ImGui::Begin("Physics Parameters", &show, 0);
	{
		ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
		ImGui::DragFloat("Radius", &Config::radius, 0.1f);
		ImGui::Checkbox("Activate Bulb", &Config::activateBulb);
	}
	ImGui::End();
		
	bool objectShow;
	ImGui::Begin("Objects", &objectShow);
	{
		for (auto& object : Objects::objects)
		{
			if (ImGui::TreeNode(object.first.c_str()))
			{	
				ImGui::Checkbox("Active", &object.second.active);
				ImGui::SameLine();
				ImGui::Checkbox("Toon", &object.second.useToon);
				ImGui::SameLine();
				ImGui::Checkbox("Stencil", &object.second.useStencil);
	
				glm::vec3 transform = object.second.GetPosition();
				ImGui::DragFloat3("Transform", &transform.x, 0.1);	

				ImGui::ColorEdit3("Color", &object.second.objectColor.x);

				ImGui::TreePop();
			}
		}

		for (int i = 0; i < Objects::cabins.size(); ++i)
		{
			ImGui::PushID(i);

			if (ImGui::TreeNode("cabin"))
			{
				auto& cabin = Objects::cabins[i];

				ImGui::Checkbox("Active", &cabin.active);
				ImGui::SameLine();
				ImGui::Checkbox("Toon", &cabin.useToon);
				ImGui::SameLine();
				ImGui::Checkbox("Stencil", &cabin.useStencil);

				glm::vec3 transform = cabin.GetPosition();
				ImGui::DragFloat3("Transform", &transform.x, 0.1);

				ImGui::ColorEdit3("Color", &cabin.objectColor.x);


				ImGui::TreePop();
			}

			ImGui::PopID();
		}
	}
	ImGui::End();

	bool lightShow;
	ImGui::Begin("Light Parameters");
	{
		for (int i = 0; i < Light::counts; ++i)
		{
			ImGui::PushID(i);

			if (ImGui::TreeNode("Light"))
			{				
				ImGui::DragFloat3("Light Position", static_cast<float*>(&Light::positions[i].x), 0.1f);
				ImGui::ColorEdit3("Light Color", static_cast<float*>(&Light::colors[i].x));
				ImGui::DragFloat("K_amb", &Light::kAmbient[i], 0.01f, 0.f, 1.f);
				ImGui::DragFloat("K_dif", &Light::kDiffuse[i], 0.01f, 0.f, 1.f);
				ImGui::DragFloat("K_spe", &Light::kSpecular[i], 0.01f, 0.f, 1.f);
				ImGui::DragFloat("Specular Power", &Light::specularPower[i], 1.f, 2.f, 256.f);

				ImGui::TreePop();
			}
			
			ImGui::PopID();
		}
	}
	ImGui::End();
}