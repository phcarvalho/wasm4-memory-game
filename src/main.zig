const w4 = @import("wasm4.zig");

export fn start() void {}

const CARD_WIDTH: u8 = 24;
const CARD_HEIGHT: u8 = 36;
const SIDE_PANEL_POS: u8 = 112;

var selected_card: u4 = 0;
var prev_state: u8 = 0;

export fn update() void {
    const gamepad = w4.GAMEPAD1.*;
    const just_pressed = gamepad & (gamepad ^ prev_state);
    if (just_pressed & w4.BUTTON_1 != 0) {
        w4.DRAW_COLORS.* = 4;
    }

    if (just_pressed & w4.BUTTON_DOWN != 0) {
        if (selected_card < 12) {
            selected_card += 4;
        }
    }

    if (just_pressed & w4.BUTTON_UP != 0) {
        if (selected_card >= 4) {
            selected_card -= 4;
        }
    }

    if (just_pressed & w4.BUTTON_LEFT != 0) {
        if (selected_card > 0 and @mod(selected_card, 4) != 0) {
            selected_card -= 1;
        }
    }

    if (just_pressed & w4.BUTTON_RIGHT != 0) {
        if (selected_card < 15 and @mod(selected_card + 1, 4) != 0) {
            selected_card += 1;
        }
    }

    prev_state = gamepad;

    w4.DRAW_COLORS.* = 4;
    var y: u8 = 2;
    var x: u8 = 2;
    for (0..16) |i| {
        if (i > 0 and i % 4 == 0) {
            x = 2;
            y += CARD_HEIGHT + 4;
        }

        if (i == selected_card) {
            w4.DRAW_COLORS.* = 3;
            w4.rect(x - 1, y - 1, CARD_WIDTH + 2, CARD_HEIGHT + 2);
            w4.DRAW_COLORS.* = 4;
        }

        w4.rect(x, y, CARD_WIDTH, CARD_HEIGHT);
        x += CARD_WIDTH + 4;
    }

    w4.rect(SIDE_PANEL_POS, 0, 48, 160);
    w4.DRAW_COLORS.* = 2;
    w4.text("P1", SIDE_PANEL_POS + 2, 52);
    w4.text("Score", SIDE_PANEL_POS + 2, 60);
}
