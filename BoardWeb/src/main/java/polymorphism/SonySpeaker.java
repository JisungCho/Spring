package polymorphism;

import org.springframework.stereotype.Component;

public class SonySpeaker implements Speaker {
	public SonySpeaker() {
		System.out.println("==> �ҴϽ���Ŀ ��ü ����");
	}
	
	public void volumeUp() {
		System.out.println("===> �Ҵ� ����Ŀ �Ҹ� �ø���.");
	}
	
	public void volumeDown() {
		 System.out.println("===> �Ҵ� ����Ŀ �Ҹ� ������.");
	}

}
