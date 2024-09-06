const w4 = @import("wasm4.zig");
const std = @import("std");

const RndGen = std.Random.DefaultPrng;

var prnd = std.Random.DefaultPrng.init(42);

const CARD_WIDTH: u8 = 24;
const CARD_HEIGHT: u8 = 36;
const SIDE_PANEL_POS: u8 = 112;

const Card = struct {
    id: u4,
    text: []const u8,
    found: bool = false,
};

const cards: [8]Card = .{
    Card{ .id = 1, .text = "1", .found = false },
    Card{ .id = 2, .text = "2", .found = false },
    Card{ .id = 3, .text = "3", .found = false },
    Card{ .id = 4, .text = "4", .found = false },
    Card{ .id = 5, .text = "5", .found = false },
    Card{ .id = 6, .text = "6", .found = false },
    Card{ .id = 7, .text = "7", .found = false },
    Card{ .id = 8, .text = "8", .found = false },
};

var cursor: u4 = 0;
var selected_card: i8 = -1;
var prev_state: u8 = 0;
var current_frame: usize = 0;

var playing = false;

var score: u4 = 0;

var game_cards: [16]Card = undefined;

fn start_game() void {
    prnd.seed(current_frame);

    game_cards = cards ** 2;
    std.Random.shuffle(prnd.random(), comptime Card, &game_cards);

    playing = true;
}

export fn start() void {}

export fn update() void {
    current_frame += 1;

    const gamepad = w4.GAMEPAD1.*;
    const just_pressed = gamepad & (gamepad ^ prev_state);

    prev_state = gamepad;

    if (!playing) {
        w4.DRAW_COLORS.* = 2;
        w4.text("Press A to start", 16, 160 / 2 - 4);

        if (just_pressed & w4.BUTTON_1 != 0) {
            start_game();
        }

        return;
    }

    if (just_pressed & w4.BUTTON_1 != 0) {
        if (selected_card == -1) {
            selected_card = cursor;
        } else if (selected_card != cursor) {
            const i_1: usize = @intCast(selected_card);
            const i_2: usize = @intCast(cursor);
            if (game_cards[i_1].id == game_cards[i_2].id) {
                game_cards[i_1].found = true;
                game_cards[i_2].found = true;

                score += 1;
            }

            selected_card = -1;

            if (score == 8) {
                cursor = 0;
                score = 0;
                playing = false;
                return;
            }
        }
    }

    if (just_pressed & w4.BUTTON_DOWN != 0) {
        if (cursor < 12) {
            cursor += 4;
        }
    }

    if (just_pressed & w4.BUTTON_UP != 0) {
        if (cursor >= 4) {
            cursor -= 4;
        }
    }

    if (just_pressed & w4.BUTTON_LEFT != 0) {
        if (cursor > 0 and @mod(cursor, 4) != 0) {
            cursor -= 1;
        }
    }

    if (just_pressed & w4.BUTTON_RIGHT != 0) {
        if (cursor < 15 and @mod(cursor + 1, 4) != 0) {
            cursor += 1;
        }
    }

    w4.DRAW_COLORS.* = 4;
    var y: u8 = 2;
    var x: u8 = 2;
    for (game_cards, 0..) |card, i| {
        defer x += CARD_WIDTH + 4;
        if (i > 0 and i % 4 == 0) {
            x = 2;
            y += CARD_HEIGHT + 4;
        }

        if (card.found) continue;

        if (selected_card == i) {
            w4.DRAW_COLORS.* = 2;
            w4.rect(x - 1, y - 1, CARD_WIDTH + 2, CARD_HEIGHT + 2);
            w4.DRAW_COLORS.* = 4;
        } else if (i == cursor) {
            w4.DRAW_COLORS.* = 3;
            w4.rect(x - 1, y - 1, CARD_WIDTH + 2, CARD_HEIGHT + 2);
            w4.DRAW_COLORS.* = 4;
        }

        w4.rect(x, y, CARD_WIDTH, CARD_HEIGHT);

        w4.DRAW_COLORS.* = 2;
        w4.text(card.text, x + 8, y + (CARD_HEIGHT / 2) - 4);
        w4.DRAW_COLORS.* = 4;
    }

    w4.rect(SIDE_PANEL_POS, 0, 48, 160);
    w4.DRAW_COLORS.* = 2;
    w4.text("P1", SIDE_PANEL_POS + 2, 52);
    w4.text("Score", SIDE_PANEL_POS + 2, 60);
}
