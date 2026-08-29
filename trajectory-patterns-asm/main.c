/* The C entry is deliberately outside the frame loop.
 * The assembly module owns the visible demo and calls the public _web64_rt ABI.
 */
void asm_trajectory_demo(void);

void main(void) {
    asm_trajectory_demo();
}
