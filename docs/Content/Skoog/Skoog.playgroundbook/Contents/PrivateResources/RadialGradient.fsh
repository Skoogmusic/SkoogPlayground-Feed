void main() {
    // A radius of .5 should mix the two colors together evenly. Tune the intensity by changing the value of radius.
    const float radius = 0.5;
    const vec2 center = vec2(0.5, 0.5);
    float dist = distance(v_tex_coord, center) / radius;
    gl_FragColor = mix(innerColor, outerColor, dist);
}
