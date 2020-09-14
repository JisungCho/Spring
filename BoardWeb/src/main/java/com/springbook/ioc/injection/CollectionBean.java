package com.springbook.ioc.injection;

import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

public class CollectionBean {
	private Properties addressList;

	public void setAddressList(Properties addressList) {
		this.addressList = addressList;
	}

	public Properties getAddressList() {
		return addressList;
	}
	
	
}
