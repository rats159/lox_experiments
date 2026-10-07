package com.craftinginterpreters.lox;

public abstract class Type {
    abstract <R> R accept(Type.Visitor<R> visitor);

    interface Visitor<R> {
        R visitNamedType(Type.Named type);
    }
    public static class Named extends Type {
        final Token name;

        public Named(Token name) {
            this.name = name;
        }

        @Override
        <R> R accept(Visitor<R> visitor) {
            return visitor.visitNamedType(this);
        }
    }
}
