#version 460 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec4 aCol;
layout(location = 2) in vec2 aTex;

layout(std430, binding = 0) buffer defaultMatrices
{
    mat4 projection;
    mat4 view;
    mat4 models[];
};

out vec4 Color;
out vec2 TexCoord;

void main()
{
    gl_Position = projection * view * models[gl_DrawID] * vec4(aPos, 1.0);
    Color       = aCol;
    TexCoord    = aTex;
}
