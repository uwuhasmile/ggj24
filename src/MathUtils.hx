final class MathUtils {
    inline public static function angleBetween(aX: Float, aY: Float, bX: Float, bY: Float):Float {
        return Math.atan2(aY - bY, aX - bX);
        /* var dot = aX * bX + aY * bY;
        final lengthA = aX * aX + aY * aY;
        final lengthB = bX * bX + bY * bY;
        if (lengthA == 0.0 || lengthB == 0.0) return 0.0;
        dot /= Math.sqrt(lengthA) * Math.sqrt(lengthB);
        return Math.acos(dot); */
    }
}