package com.springbook.biz.common;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Service;

@Service
@Aspect
public class AfterThrowingAdvice {
	@Pointcut("execution(* com.springbook.biz..*Impl.*(..))")
	public void allPointcut() {
	}
	
	@AfterThrowing(pointcut = "allPointcut()", throwing = "exceptionObj")
	public void AfterThrowingLog(JoinPoint jp , Exception exceptionObj) {
		String method = jp.getSignature().getName();
		System.out.println("[예외 처리] :"+method+"() 수행 중 예외 발생 : "+exceptionObj.getMessage());
	}
}
