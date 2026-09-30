const std = @import("std");

pub fn ZProto(comptime handlers: anytype) type {
    const Handlers = @TypeOf(handlers);
    const handler_fields = std.meta.fields(Handlers);

    return struct {
        pub const Method = std.meta.FieldEnum(Handlers);
        pub const Instance = MakeInstance();

        pub fn init(writer: *std.Io.Writer) Instance {
            var inst: Instance = undefined;
            inline for (handler_fields) |f| {
                @field(inst, f.name) = .{ .writer = writer };
            }
            return inst;
        }

        fn Handler(comptime m: Method) type {
            const H = @TypeOf(@field(handlers, @tagName(m)));
            if (@typeInfo(H) != .@"fn") {
                @compileError("rpc method '" ++ @tagName(m) ++ "' is not a function");
            }
            return H;
        }

        fn Bound(comptime m: Method) type {
            const name = @tagName(m);

            return struct {
                writer: *std.Io.Writer,

                pub fn call(self: @This(), args: std.meta.ArgsTuple(Handler(m))) std.Io.Writer.Error!void {
                    try self.writer.writeByte(@intCast(name.len));
                    try self.writer.writeAll(name);
                    inline for (args) |arg| {
                        try writeValue(self.writer, arg);
                    }
                }
            };
        }

        fn writeValue(writer: *std.Io.Writer, value: anytype) std.Io.Writer.Error!void {
            const T = @TypeOf(value);
            switch (@typeInfo(T)) {
                .int => try writer.writeInt(T, value, .little),
                .float => try writer.writeInt(std.meta.Int(.unsigned, @bitSizeOf(T)), @bitCast(value), .little),
                .bool => try writer.writeByte(@intFromBool(value)),
                else => @compileError("unsupported rpc argument type: " ++ @typeName(T)),
            }
        }

        fn MakeInstance() type {
            var names: [handler_fields.len][]const u8 = undefined;
            var types: [handler_fields.len]type = undefined;
            var attrs: [handler_fields.len]std.builtin.Type.StructField.Attributes = undefined;

            for (handler_fields, 0..) |f, i| {
                names[i] = f.name;
                types[i] = Bound(@field(Method, f.name));
                attrs[i] = .{};
            }

            return @Struct(.auto, null, &names, &types, &attrs);
        }
    };
}
