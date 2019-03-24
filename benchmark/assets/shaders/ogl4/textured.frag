#version 450 core

out vec4 FragColor;

in vec4 Color;
in vec2 TexCoord;

uniform sampler2D defaultTexture;

void main()
{
    FragColor = texture(defaultTexture, TexCoord) * Color;
}
