import React, { useEffect, useRef } from 'react';

interface MathTextProps {
  text: string;
  className?: string;
}

export const MathText: React.FC<MathTextProps> = ({ text, className = '' }) => {
  const containerRef = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    // Process inline $...$ or display $$...$$ math notation
    const regex = /(\$\$[\s\S]+?\$\$|\$[\s\S]+?\$)/g;
    const parts = text.split(regex);

    containerRef.current.innerHTML = '';

    parts.forEach((part) => {
      if (!part) return;

      const katexObj = (window as any).katex;

      if (part.startsWith('$$') && part.endsWith('$$')) {
        const formula = part.slice(2, -2);
        const div = document.createElement('div');
        div.className = 'my-2 text-center overflow-x-auto';
        try {
          if (katexObj && typeof katexObj.render === 'function') {
            katexObj.render(formula, div, { displayMode: true, throwOnError: false });
          } else {
            div.textContent = formula;
          }
        } catch (e) {
          div.textContent = formula;
        }
        containerRef.current?.appendChild(div);
      } else if (part.startsWith('$') && part.endsWith('$')) {
        const formula = part.slice(1, -1);
        const span = document.createElement('span');
        try {
          if (katexObj && typeof katexObj.render === 'function') {
            katexObj.render(formula, span, { displayMode: false, throwOnError: false });
          } else {
            span.textContent = formula;
          }
        } catch (e) {
          span.textContent = formula;
        }
        containerRef.current?.appendChild(span);
      } else {
        const span = document.createElement('span');
        span.textContent = part;
        containerRef.current?.appendChild(span);
      }
    });
  }, [text]);

  return <span ref={containerRef} className={`inline-block ${className}`} />;
};
