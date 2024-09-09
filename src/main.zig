const w4 = @import("wasm4.zig");
const std = @import("std");

const sprites = @import("sprites.zig");

const RndGen = std.Random.DefaultPrng;

var prnd = std.Random.DefaultPrng.init(42);

const CARD_SIZE: u8 = 24;
const SIDE_PANEL_POS: u8 = 112;

const Card = struct {
    id: u4,
    sprite: *const [144]u8,
    found: bool = false,
};

const cards: [8]Card = .{
    Card{ .id = 1, .sprite = &sprites.card_front_1, .found = false },
    Card{ .id = 2, .sprite = &sprites.card_front_2, .found = false },
    Card{ .id = 3, .sprite = &sprites.card_front_3, .found = false },
    Card{ .id = 4, .sprite = &sprites.card_front_4, .found = false },
    Card{ .id = 5, .sprite = &sprites.card_front_5, .found = false },
    Card{ .id = 6, .sprite = &sprites.card_front_6, .found = false },
    Card{ .id = 7, .sprite = &sprites.card_front_7, .found = false },
    Card{ .id = 8, .sprite = &sprites.card_front_8, .found = false },
};

var prev_state: u8 = 0;
var current_frame: usize = 0;

var cursor: u4 = 0;
var selected_card: [2]i8 = undefined;
var game_cards: [16]Card = undefined;
var playing = false;
var score: u4 = 0;

var checking_cards: bool = false;
var checking_timer: i8 = 0;

fn start_game() void {
    prnd.seed(current_frame);

    score = 0;
    cursor = 0;
    selected_card = .{ -1, -1 };
    game_cards = cards ** 2;
    std.Random.shuffle(prnd.random(), comptime Card, &game_cards);

    playing = true;
}

fn changeCursor(val: i8, cur_cursor: u4) void {
    const next_cursor: i8 = cur_cursor + val;

    if (next_cursor < 0) {
        if (!game_cards[cur_cursor].found) {
            return;
        }

        return changeCursor(1, cur_cursor);
    } else if (next_cursor >= 16) {
        if (!game_cards[cur_cursor].found) {
            return;
        }
        return changeCursor(-1, cur_cursor);
    }

    const current_card: *Card = &game_cards[@intCast(next_cursor)];
    if (current_card.found) {
        changeCursor(val, @intCast(next_cursor));
    } else {
        cursor = @intCast(next_cursor);
    }
}

export fn start() void {
    w4.PALETTE.* = .{
        0xeff9d6,
        0xba5044,
        0x7a1c4b,
        0x1b0326,
    };
}

export fn update() void {
    current_frame += 1;

    const gamepad = w4.GAMEPAD1.*;
    const just_pressed = gamepad & (gamepad ^ prev_state);

    prev_state = gamepad;

    if (!playing) {
        w4.DRAW_COLORS.* = 2;
        if (score == 8) {
            w4.text("You won!", 50, 160 / 2 - 44);
        } else {
            w4.text("Memory Game", 36, 160 / 2 - 44);
        }
        w4.text("Press X to start", 16, 160 / 2 - 4);

        if (just_pressed & w4.BUTTON_1 != 0) {
            start_game();
        }

        return;
    }

    if (!checking_cards and just_pressed & w4.BUTTON_1 != 0) {
        if (selected_card[0] == -1) {
            selected_card[0] = cursor;
        } else if (cursor != selected_card[0]) {
            selected_card[1] = cursor;

            checking_cards = true;
        }
    }

    if (checking_cards) {
        checking_timer += 1;

        if (checking_timer == 60) {
            const card_1 = &game_cards[@intCast(selected_card[0])];
            const card_2 = &game_cards[@intCast(selected_card[1])];

            if (card_1.id == card_2.id) {
                card_1.found = true;
                card_2.found = true;

                score += 1;

                if (score == 8) {
                    playing = false;
                } else if (cursor == selected_card[0] or cursor == selected_card[1]) {
                    changeCursor(1, cursor);
                }
            }

            checking_cards = false;
            checking_timer = 0;

            selected_card[0] = -1;
            selected_card[1] = -1;
        }
    }

    if (just_pressed & w4.BUTTON_DOWN != 0) {
        changeCursor(4, cursor);
    }

    if (just_pressed & w4.BUTTON_UP != 0) {
        changeCursor(-4, cursor);
    }

    if (just_pressed & w4.BUTTON_LEFT != 0) {
        changeCursor(-1, cursor);
    }

    if (just_pressed & w4.BUTTON_RIGHT != 0) {
        changeCursor(1, cursor);
    }

    w4.DRAW_COLORS.* = 4;
    var y: u8 = 17;
    var x: u8 = 17;
    for (game_cards, 0..) |card, i| {
        defer x += CARD_SIZE + 10;
        if (i > 0 and i % 4 == 0) {
            x = 17;
            y += CARD_SIZE + 10;
        }

        if (card.found) continue;

        if (i == cursor) {
            w4.DRAW_COLORS.* = 0x3303;
            w4.blit(&sprites.card_selection, x, y, CARD_SIZE, CARD_SIZE, w4.BLIT_1BPP);
        }

        w4.DRAW_COLORS.* = 0x4021;
        if (selected_card[0] == i or selected_card[1] == i) {
            w4.blit(card.sprite, x, y, CARD_SIZE, CARD_SIZE, w4.BLIT_2BPP);
        } else {
            w4.blit(&sprites.card_back, x, y, CARD_SIZE, CARD_SIZE, w4.BLIT_2BPP);
        }
    }
}
