/* C enters native assembly once. The application-owned assembly module owns
 * trajectory stepping, animation cadence, VIC projection, and the PAL loop.
 */
void asm_trajectory_actors_demo(void);

void main(void) {
    asm_trajectory_actors_demo();
}
