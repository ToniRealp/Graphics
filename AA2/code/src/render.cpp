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
	const float zNear = 1.f;
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

	float panv[3] = { 0.f, -5.f, -15.f };
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

////////////////////////////////////////////////// AXIS
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

////////////////////////////////////////////////// CUBE
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

/////////////////////////////////////////////////

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
}

namespace Octahedrons
{
	unsigned int vao, vbo;
	unsigned int program;

	glm::vec3 points[20];
	glm::vec3 velocities[20];

	glm::mat4& view = RV::_modelView;
	glm::mat4& projection = RV::_projection;

	void Setup()
	{
		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);

		glGenBuffers(1, &vbo);
		glBindBuffer(GL_ARRAY_BUFFER, vbo);

		for (auto& point : points)
		{
			point = { (rand() % 1000) / 100.f, (rand() % 1000) / 100.f,  (rand() % 1000) / 100.f };
			point -= 5;
		}

		for (auto& velocity : velocities)
			velocity = { (rand() % 1000) / 1000.f, (rand() % 1000) / 1000.f,  (rand() % 1000) / 1000.f };

		glBufferData(GL_ARRAY_BUFFER, sizeof(points), static_cast<float*>(&points[0].x), GL_STATIC_DRAW);

		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, nullptr);


		const auto vertex_shader = Shader::ParseShader("res/exercise_1/Vertex.shader");
		const auto fragment_shader = Shader::ParseShader("res/exercise_1/Fragment.shader");
		const auto geometry_shader = Shader::ParseShader("res/exercise_1/Geometry.shader");

		program = Shader::CreateProgram(vertex_shader, fragment_shader, geometry_shader);
	}

	void Draw(float dt)
	{
		for (int i = 0; i < 20; i++)
		{
			points[i] += velocities[i] * dt;

			if (points[i].x < -5 || points[i].x > 5)
				velocities[i].x *= -1;

			if (points[i].y < -5 || points[i].y > 5)
				velocities[i].y *= -1;

			if (points[i].z < -5 || points[i].z > 5)
				velocities[i].z *= -1;
		}

		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glBufferData(GL_ARRAY_BUFFER, sizeof(points), static_cast<float*>(&points[0].x), GL_STATIC_DRAW);

		glBindVertexArray(vao);

		glUseProgram(program);
		Shader::SetMat4(program, "view", view);
		Shader::SetMat4(program, "projection", projection);

		glDrawArrays(GL_POINTS, 0, 20);
	}

	void Clean()
	{
		glDeleteBuffers(1, &vbo);
	}
};

namespace HoneyCombs
{
	unsigned int vao, vbo;
	unsigned int program;

	glm::mat4& view = RV::_modelView;
	glm::mat4& projection = RV::_projection;

	float alpha = 0.0f;

	void Setup()
	{
		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);

		glGenBuffers(1, &vbo);
		glBindBuffer(GL_ARRAY_BUFFER, vbo);

		glm::vec3 points[20];
		bool left = true;
		float x = -0.707*2;
		float z = 0.354f;
		for (int i = 0; i < 20; i++)
		{
			if (i >= 15)
			{
				if (left)
					points[i] = { x, 1.061f , z };
				else
					points[i] = { x, 1.061f , -z };
			}
			else if (i >= 10)
			{
				if (left)
					points[i] = { x, 0.354f , z };
				else
					points[i] = { x, 0.354f , -z };
			}
			else if (i >= 5)
			{
				if (left)
					points[i] = { x, -0.354f , z };
				else
					points[i] = { x, -0.354f , -z };
			}
			else
			{
				if (left)
					points[i] = { x, -1.061f , z };
				else
					points[i] = { x, -1.061f , -z };
			}

			left = !left;
			x += 0.707;
			if (x >= 0.707 * 2)
				x = 0.707 * -2;
		}

		glBufferData(GL_ARRAY_BUFFER, sizeof(points), static_cast<float*>(&points[0].x), GL_STATIC_DRAW);

		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, nullptr);


		const auto vertex_shader = Shader::ParseShader("res/exercise_2/Vertex.shader");
		const auto fragment_shader = Shader::ParseShader("res/exercise_2/Fragment.shader");
		const auto geometry_shader = Shader::ParseShader("res/exercise_2/Geometry.shader");

		program = Shader::CreateProgram(vertex_shader, fragment_shader, geometry_shader);
	}

	void Draw(float dt)
	{
		glBindVertexArray(vao);

		glUseProgram(program);
		Shader::SetMat4(program, "view", view);
		Shader::SetMat4(program, "projection", projection);

		alpha += dt;
		if (alpha >= glm::two_pi<float>()) alpha = 0;
		Shader::SetFloat(program, "alpha", (glm::sin(alpha) + 1.0f) / 2.0f);

		glDrawArrays(GL_POINTS, 0, 20);
	}

	void Clean()
	{
		glDeleteBuffers(1, &vbo);
	}
}

namespace Voronoid
{
	unsigned int vao, vbo;
	unsigned int program[2];

	glm::mat4& view = RV::_modelView;
	glm::mat4& projection = RV::_projection;

	float alpha = 0.0f;
	float random_values[8];

	void GenerateRandom(float dt)
	{
		alpha += dt / 2.0f;
		if (alpha >= glm::two_pi<float>()) alpha = 0;
		for (int i = 0; i < 8; ++i)
		{
			random_values[i] = glm::perlin(glm::vec2(sin(i * alpha) / 2.f, sin(i * alpha) / 2.f));
		}
	}

	void Setup()
	{
		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);

		glGenBuffers(1, &vbo);
		glBindBuffer(GL_ARRAY_BUFFER, vbo);

		glm::vec3 points[1];

		glBufferData(GL_ARRAY_BUFFER, sizeof(points), static_cast<float*>(&points[0].x), GL_STATIC_DRAW);

		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, nullptr);


		auto vertex_shader = Shader::ParseShader("res/exercise_3/face/Vertex.shader");
		auto fragment_shader = Shader::ParseShader("res/exercise_3/face/Fragment.shader");
		auto geometry_shader = Shader::ParseShader("res/exercise_3/face/Geometry.shader");
		program[0] = Shader::CreateProgram(vertex_shader, fragment_shader, geometry_shader);

		vertex_shader = Shader::ParseShader("res/exercise_3/lines/Vertex.shader");
		fragment_shader = Shader::ParseShader("res/exercise_3/lines/Fragment.shader");
		geometry_shader = Shader::ParseShader("res/exercise_3/lines/Geometry.shader");
		program[1] = Shader::CreateProgram(vertex_shader, fragment_shader, geometry_shader);
	}

	void Draw(float dt)
	{
		GenerateRandom(dt);

		glBindVertexArray(vao);

		glUseProgram(program[0]);
		Shader::SetMat4(program[0], "view", view);
		Shader::SetMat4(program[0], "projection", projection);
		Shader::SetFloatArray(program[0], "random_values", 8, random_values);
		glDrawArrays(GL_POINTS, 0, 1);

		glUseProgram(program[1]);
		Shader::SetMat4(program[1], "view", view);
		Shader::SetMat4(program[1], "projection", projection);
		Shader::SetFloatArray(program[1], "random_values", 8, random_values);
		glLineWidth(10.0f);
		glDrawArrays(GL_LINES, 0, 1);
	}

	void Clean()
	{
		glDeleteBuffers(1, &vbo);
	}
}

enum class Scene { EXERCISE_1, EXERCISE_2, EXERCISE_3 };

Scene scene{ Scene::EXERCISE_1 };
std::string sceneName{ "TRUNCATED OCTAHEDRONS" };

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


	Octahedrons::Setup();
	HoneyCombs::Setup();
	Voronoid::Setup();
}

void GLcleanup()
{
	Axis::cleanupAxis();


	Octahedrons::Clean();
	HoneyCombs::Clean();
	Voronoid::Clean();
}

void GLrender(float dt)
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	RV::_modelView = glm::mat4(1.f);
	RV::_modelView = glm::translate(RV::_modelView, glm::vec3(RV::panv[0], RV::panv[1], RV::panv[2]));
	RV::_modelView = glm::rotate(RV::_modelView, RV::rota[1], glm::vec3(1.f, 0.f, 0.f));
	RV::_modelView = glm::rotate(RV::_modelView, RV::rota[0], glm::vec3(0.f, 1.f, 0.f));

	RV::_MVP = RV::_projection * RV::_modelView;
	Axis::drawAxis();


	switch (scene)
	{
	case Scene::EXERCISE_1:
		Octahedrons::Draw(dt);
		break;

	case Scene::EXERCISE_2:
		HoneyCombs::Draw(dt);
		break;

	case Scene::EXERCISE_3:
		Voronoid::Draw(dt);
		break;
	}

	ImGui::Render();
}

void GUI()
{
	bool show = true;
	ImGui::Begin("Physics Parameters", &show, 0);
	{
		ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);

		if (ImGui::Button("Change Exercise"))
		{
			scene = static_cast<Scene>((static_cast<int>(scene) + 1) % 3);

			switch (scene)
			{
			case Scene::EXERCISE_1:
				sceneName = "TRUNCATED OCTAHEDRONS";
				break;

			case Scene::EXERCISE_2:
				sceneName = "HONEYCOMBS";
				break;

			case Scene::EXERCISE_3:
				sceneName = "VORONOID";
				break;
			}
		}

		ImGui::Text(sceneName.c_str());
	}

	ImGui::End();
}