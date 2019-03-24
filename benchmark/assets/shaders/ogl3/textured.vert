#version 330 core

in vec3 aPos;
in vec4 aCol;
in vec2 aTex;

uniform mat4 projection;
uniform mat4 view;

out vec4 Color;
out vec2 TexCoord;

void main()
{
    gl_Position = projection * view * vec4(aPos, 1.0);
    Color       = aCol;
    TexCoord    = aTex;
}
