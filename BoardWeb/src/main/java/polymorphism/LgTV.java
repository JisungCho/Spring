package polymorphism;

import javax.annotation.Resource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;

@Component("tv")
public class LgTV implements TV{
	
	
	@Autowired
	private Speaker speaker;
	
	public LgTV() {
		System.out.println("���� ��ü ����");
	}
	
	@Override
	public void powerOn() {
		System.out.println("���� ���� �Ҵ�");
	}

	@Override
	public void powerOff() {
		System.out.println("���� ���� ����");
	}

	@Override
	public void volumeUp() {
		speaker.volumeUp();
	}

	@Override
	public void volumeDown() {
		speaker.volumeDown();
	}
}
