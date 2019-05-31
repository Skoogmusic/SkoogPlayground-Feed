void main() {
    float diag = 0.5 * ((1.0 - v_tex_coord.x) + v_tex_coord.y);
    gl_FragColor = mix(endColor, startColor, diag);
}
