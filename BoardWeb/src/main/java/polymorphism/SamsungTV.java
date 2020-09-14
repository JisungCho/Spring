package polymorphism;

public class SamsungTV implements TV {
	
	private Speaker speaker;
	private int price;
	
	public void initMethod() {
		System.out.println("��ü �ʱ�ȭ �۾� ó��");
	}
	public void destroyMethod() {
		System.out.println("��ü ���� ���� ó�� �� �۾� ó��");
	}
	
	public SamsungTV() {
		System.out.println("===> SamsungTV��ü ����");
	}
	
	public SamsungTV(Speaker speaker) {
		System.out.println("===> SamsungTV(2) ��ü ����");
		this.speaker = speaker;
	}
	
	public SamsungTV(Speaker speaker,int price) {
		System.out.println("===> SamsungTV(3) ��ü ����");
		this.speaker = speaker;
		this.price = price;
	}
	
	
	public void setSpeaker(Speaker speaker) {
		System.out.println("===>setSpeaker() ȣ��");
		this.speaker = speaker;
	}
	public void setPrice(int price) {
		System.out.println("===>setPrice() ȣ��");
		this.price = price;
	}
	public void powerOn() {
		System.out.println("�Ｚ ���� �Ҵ�. (����: "+price+" )");
	}
	
	public void powerOff() {
		System.out.println("�Ｚ ���� ����");
	}
	
	public void volumeUp() {
		speaker.volumeUp();
	}
	
	public void volumeDown() {
		speaker.volumeDown();
	}
}
